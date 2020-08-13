classdef sessionManagerClass < handle
    
    % sessionManagerClass objects group sequences that make up a single
    % session and are resposible for ordering the sequences within the
    % session, controlling inter-sequence and inter-session rest periods
    % and interfacing with the sequenceDispatchEngineClass
    
    properties
        
        sequences % cell array of sequences that make up a single session
        seqOrder % the order to show the sequences within a session
        seqCount % the number of the current sequence
        
        nSessions % the number of sessions in a presentation run
        sessCount % the number of the current session
        
        interSeqInterval % the time between sequences within a session
        interSessInterval % time between sessions
        
        delayInterStim % wait to start interstim timer
        interStimPeriod % delay between interstim timer events
        
        orderType % 'sequential', 'random', 'specified' or 'interleaved'
        
        deleteOnComplete % optional array of objects to delete at session completion
        
        % If true, stim details will be sent to TTL system during the
        % startPresentation method
        % See ttlInterfaceClass.sendStringAsEvent and
        % stimulusSequenceClass.tellSequenceDetails for more information
        sendStimDetailsToTTL
                
    end
    
    properties (Access=protected)
        printFcn % function handle for print statements
        expLog % for keeping experimental records
        goAhead % verify screen availability before presentation
        scaSupport % interface with the ScrnCrtlApp
        ttlInterface % used to send TTL pulses
        sequenceCounts % used when orderType == interleaved
        dispatchEngine % sequenceDispatchEngineClass object
        seqStartTimer % used to start the next sequence
        interStimTimer % perform interstimulus operations
        abortListener
        sequenceCompletionListener
        startListener
        stopListener
        ttlLogListener
        startTime % track how long execution required
    end
    
    events
        PresentationStarting
        SessionNotification
        PresentationComplete
    end
    
    methods
        
        function obj = sessionManagerClass(supportFlag)
            % Initialize arrays
            obj.sequences = {};
            obj.seqOrder = [];
            obj.seqCount = 0;
            obj.sessCount = 0;
            obj.nSessions = 1;
            % Set default parameters
            obj.orderType = 'sequential';
            obj.sequenceCounts = [];
            obj.interSeqInterval = 10;
            obj.interSessInterval = 10;
            obj.delayInterStim = 1;
            obj.interStimPeriod = 0.5;
            % Initialize objects
            obj.dispatchEngine = sequenceDispatchEngineClass.getEngine;
            obj.interStimTimer = [];
            obj.abortListener = [];
            obj.startListener = addlistener(obj,'PresentationStarting',...
                @(src,event)startEvent_Callback(obj));
            obj.stopListener = [];
            obj.scaSupport = false;
            obj.deleteOnComplete = [];
            % By default use fprintf
            obj.printFcn = @fprintf;
            
            % Get the hardward interface for ttl pulses
            obj.ttlInterface = ttlInterfaceClass.getTTLInterface;
            
            % Setup for logging
            obj.expLog = experimentalRecordsClass;
            obj.sendStimDetailsToTTL = obj.ttlInterface.TTLMetaDataEnabled;
            obj.ttlLogListener = addlistener(obj.ttlInterface,...
                'TTLMetadataStateToggled',...
                @(src,event)updateLogging(obj));
            
            obj.goAhead = true;
            
            if nargin > 0
                switch lower(supportFlag)
                    case 'scasupport'
                        provideSCASupport(obj);
                    otherwise
                        obj.printFcn('unknown support flag %s\n',...
                            supportFlag);
                end
            end
        end
        
        function delete(obj)
            deleteTimers([obj.seqStartTimer obj.interStimTimer]);
            delete(obj.abortListener);
            delete(obj.startListener);
            delete(obj.stopListener);
            delete(obj.deleteOnComplete);
            delete(obj.sequenceCompletionListener);
            delete(obj.ttlLogListener);
        end
        
        function addSequences(obj,ssos)
            % Add sequences to the session
            n = numel(obj.seqOrder); % current number of elements
            newIndici = n+(1:numel(ssos));
            obj.sequences(newIndici) = ssos;
            obj.seqOrder(newIndici) = newIndici;
        end
        
        function setNumberOfSessions(obj,nSessions)
            obj.nSessions = nSessions;
        end
        
        function setOrderType(obj,orderType,seqOrder)
            lowOrderType = lower(orderType);
            switch lowOrderType
                case {'sequential'...
                        'random'...
                        'fullyinterleaved'...
                        'interleavewithrepeats'}
                    obj.orderType = lowOrderType;
                case 'specified'
                    if nargin < 3
                        error('%s.setOrderType(specified) require a seqOrder',...
                            class(obj));
                    end
                    obj.orderType = lowOrderType;
                    obj.seqOrder = seqOrder;
                otherwise
                    error('unknown order type %s',orderType);
            end
        end
        
        function reqTime = estimateTime(obj)
            reqTime = 0;
            % calculate cumulative time for all the sequences with the isi
            for iS = 1:numel(obj.seqOrder)
                theSequence = obj.sequences{obj.seqOrder(iS)};
                reqTime = reqTime + ...
                    calculateSequenceTime(theSequence) + ...
                    obj.interSeqInterval;
            end
            % No interSeqInterval after last sequence in a session
            reqTime = reqTime - obj.interSeqInterval; % time for 1 session
            reqTime = reqTime * obj.nSessions; % time for all sessions
            % Add in the intersession intervals
            reqTime = reqTime + obj.interSessInterval*(obj.nSessions-1);            
        end
        
        function startPresentation(obj)
            notify(obj,'PresentationStarting');
            if ~obj.goAhead
                error('%s.startPresentation- goAhead is negative');
            end
            
            % Make sure the screen is open and all of the sequences to
            % update timing based on the screen refresh rate
            sio = screenInterfaceClass.returnInterface;
            sio.openScreen;
            for iS = 1:numel(obj.sequences)
                obj.sequences{iS}.alignTiming;
            end
            
            % Log the experimental details, show a warning if logging is
            % not configured
            if ~obj.expLog.isReadyToLog
                obj.expLog.showConfigWarning(...
                    sprintf('%s: experimentalRecordsClass not ready. No logging will occur.\n',mfilename));
            end
            obj.logSessionDetails;
            
            % Create the sequence order for this session
            generateSequenceOrder(obj); 
            % Get the start time and estimate completion time
            obj.startTime = GetSecs;
            sdt = rem(now,1);
            obj.printFcn('Stimulus Presentation Starting at %s\n',...
                datestr(sdt,13));
            reqTime = estimateTime(obj);
            obj.printFcn('Presentation will complete at ~ %s (%s)\n',...
                datestr(sdt+datenum(0,0,0,0,0,reqTime),13),...
                secs2Str(reqTime));
            
            % Grab the dispatchEngine
            siezeEngine(obj.dispatchEngine);
            
            % Start presentation cycle
            obj.seqCount = 1;
            obj.sessCount = 1;
            startRecording(obj.ttlInterface);
            startSequence(obj);
            
        end
        
    end 
    
    methods (Hidden=true)
        
        % Methods to provide support for the ScrnCtrlApp environment ------
        function provideSCASupport(obj)
            % Interface with the ScrnCtrlApp
            obj.scaSupport = true;
            % delete(obj.ttlInterface);
            % obj.ttlInterface = ttlInterfaceClass.getHardwareInterface;
            obj.printFcn = @scaPrintf;
            supportUserAbort(obj,ScrnCtrlApp('requestEventSupport'));
            obj.stopListener = addlistener(obj,'PresentationComplete',...
                @(src,event)ScrnCtrlApp('releaseSynchronousScreenControl'));
            obj.dispatchEngine.provideSCASupport();
            drawnow();
        end
        
        function supportUserAbort(obj,noteObj)
            % Listen to noteObj for 'UserAbort' events
            obj.abortListener = addlistener(noteObj,'UserAbort',...
                @(src,event)abortPresentation(obj));
        end
        
        function startEvent_Callback(obj)
            % Check to make sure the dispatch engine is not locked before
            % starting the presentation. If ScrnCtrlApp support is needed
            % request control and update the goAhead flag accordingly
            obj.goAhead = ~obj.dispatchEngine.isLocked;
            if obj.scaSupport
                obj.goAhead = obj.goAhead && ...
                    ScrnCtrlApp('requestSynchronousScreenControl');
            end
        end
        
        function generateSequenceOrder(obj)
            % Figure out the order in which sequences will be called based
            % on the user selected state of obj.orderType
            switch obj.orderType
                case 'sequential'
                    obj.seqOrder = 1:numel(obj.sequences);
                case 'random'
                    obj.seqOrder = randperm(numel(obj.sequences));
                case 'fullyinterleaved'
                    % First time through figure out how many times each
                    % sequence should be shown and save then set each
                    % sequence repeat count to zero
                    if isempty(obj.sequenceCounts)
                        nS = numel(obj.sequences);
                        obj.sequenceCounts = zeros(1,nS);
                        for iS = 1:nS
                            obj.sequenceCounts(iS) = ...
                                obj.sequences{iS}.nRepeats + 1;
                            obj.sequences{iS}.nRepeats = 0;
                        end
                    end
                    % Randomly interleave all the sequences
                    n = sum(obj.sequenceCounts);
                    tmpOrder = zeros(1,n);
                    count = 1;
                    for iS = 1:numel(obj.sequences)
                        nS = obj.sequenceCounts(iS);
                        tmpOrder(count:count+nS-1) = iS;
                        count = count + nS;
                    end
                    obj.seqOrder = tmpOrder(randperm(n));
                case 'interleavewithrepeats'
                    % Calculate the number of presentations for each
                    % sequence then setup to randomize presentations in one
                    % sessions
                    tmpOrder = 1:numel(obj.sequences);
                    tmpOrder = repmat(tmpOrder,1,obj.nSessions);
                    obj.seqOrder = tmpOrder(randperm(numel(tmpOrder)));
                    obj.nSessions = 1;
                case 'specified'
                    % Already specified so do nothing
            end
        end
        
        function interval = getInterSeqInterval(obj)
            interval = obj.interSeqInterval;
        end
        
        function interval = getInterSessInterval(obj)
            interval = obj.interSessInterval;
        end        
        
        function allDetailStrs = logSessionDetails(obj)
            allDetailStrs = cell(1,500);
            nSeq = numel(obj.sequences);
            str = sprintf('%s,nSequences:%i',class(obj),nSeq);
            allDetailStrs{1} = str;
            obj.expLog.logMessage(str);
            str = '0:ID:Noise,EvntValue:0,';
            obj.expLog.logMessage(str);
            allDetailStrs{2} = str;
            counter = 2;
            for iS = 1:nSeq
                theSequence = obj.sequences{iS};
                theDetails = theSequence.tellSequenceDetails;
                obj.expLog.logMessage(theDetails);
                for iD = 1:length(theDetails)
                    counter = counter + 1;
                    allDetailStrs{counter} = theDetails{iD};
                end
            end
            if obj.sendStimDetailsToTTL
                obj.printFcn('Sending metadata to the TTL system...\n');
                drawnow;
                obj.ttlInterface.sendStringAsEvent(allDetailStrs(1:counter));
            end
        end
                
        function startSequence(obj,src)
            if obj.seqCount == 1
                obj.printFcn('Starting Session %i\n',obj.sessCount);
            end
            % Delete old timers
            if nargin > 1
                stop(src);
            end
            deleteTimers([obj.seqStartTimer obj.interStimTimer]);
            
            % Load the current sequence (based on the seqCount and
            % seqOrder) into the dispatch engine and start. Create a
            % callback that will respond to SequenceComplete events
            iSeq = obj.seqOrder(obj.seqCount);
            sso = obj.sequences{iSeq};
            obj.sequenceCompletionListener = addlistener(sso,...
                'SequenceComplete',...
                @(src,event)sequenceComplete_Callback(obj,event));
            loadSequence(obj.dispatchEngine,sso);
            startSequence(obj.dispatchEngine);
        end
        
        function sequenceComplete_Callback(obj,eventData)
            % use eventData to see if the sequence completed normally or
            % was aborted - if aborted, also abort the session.  If normal
            % completion, start the interstimulus routine or end the
            % presentation run
            % fprintf('sequenceComplete_Callback(%s)\n',eventData.descStr);
            delete(obj.sequenceCompletionListener);
            switch eventData.descStr
                case 'Normal'
                    lastSeq = obj.seqCount == getNSequences(obj);
                    lastSess = obj.sessCount == obj.nSessions;
                    if lastSeq && lastSess
                        %fprintf('lastSeq&lastSess\n');
                        % If this was the last sequence of the last session
                        % presentation is complete
                        stopPresentation(obj,'Normal');
                        return;
                    elseif lastSeq
                        %fprintf('lastSeq\n');
                        % If this is the last sequence, increment the
                        % session counter, reset the seqCounter and
                        % regenerate the sequence order
                        obj.seqCount = 1;
                        obj.sessCount = obj.sessCount + 1;
                        generateSequenceOrder(obj);
                        interval = getInterSessInterval(obj);
                    else
                        %fprintf('not last\n');
                        obj.seqCount = obj.seqCount + 1;
                        interval = getInterSeqInterval(obj);
                    end
                case 'Abort'
                    stopPresentation(obj,'Abort');
                    return;
                otherwise 
                    return;
            end
            if interval == 0
                % If there is no interval, start the next sequence
                % immediately
                startSequence(obj);
            else
                % Create a timer that will start the next sequence
                obj.seqStartTimer = timer('Name','seqStartTimer',...
                    'StartDelay',round(interval),...
                    'TimerFcn',@(src,event)startSequence(obj,src));
                start(obj.seqStartTimer);
                % Call a method that will setup anything else that should
                % be done during the interstimulus period
                setupInterSequenceActivity(obj,interval);
            end
        end
        
        function setupInterSequenceActivity(obj,interval)
            % Create a timer that will perform an operation
            % periodically during the interstimulus interval
            collectionWindow = interval - obj.delayInterStim - ...
                obj.interStimPeriod;
            nFire = floor(collectionWindow/obj.interStimPeriod);
            if nFire >= 1
                obj.interStimTimer = timer('Name','interStimTimer',...
                    'ExecutionMode','fixedRate',...
                    'StartDelay',round(obj.delayInterStim),...
                    'Period',obj.interStimPeriod,...
                    'TasksToExecute',nFire,...
                    'StartFcn',@(src,event)interStimStartFcn(obj),...
                    'TimerFcn',@(src,event)interStimFnc(obj,src,event));
                start(obj.interStimTimer);
            end
        end
        
        function interStimStartFcn(obj)
            % Set the ttl word to 0
            setEventWord(obj.ttlInterface,0);
        end
        
        function interStimFnc(obj,src,eventData) %#ok<INUSD>
            %fprintf('interStimFnc: TasksExecuted=%i Running=%s at %s\n',...
            %    get(src,'TasksExecuted'),get(src,'Running'),datestr(now));
            strobe(obj.ttlInterface);
        end
        
        function abortPresentation(obj)
            % Make sure timers don't start a new sequence before abort can
            % complete
            % try obj.seqStartTimer.stop; end; %#ok<TRYNC>
            % try obj.interStimTimer.stop; end; %#ok<TRYNC>
            abortSequence(obj.dispatchEngine);
            stopPresentation(obj,'Abort');
        end
        
        function stopPresentation(obj,stopType)
            % fprintf('%s.stopPresentation(%s)\n',class(obj),stopType);
            deleteTimers([obj.seqStartTimer obj.interStimTimer]);
            delete(obj.sequenceCompletionListener);
            % Since right now sca support is called in scripts old smos can
            % persist and respond to abort signals meant for subsequent
            % smos - to prevent this clear the abortListener. In the future
            % this logic might want to be made a bit better (like have the
            % SCA tell object that has requested support to withdraw it
            % when a new object request support)
            delete(obj.abortListener);
            delete(obj.deleteOnComplete);
            setEventWord(obj.ttlInterface,0);
            stopRecording(obj.ttlInterface);
            reqTime = GetSecs() - obj.startTime;
            obj.printFcn('Stimulus Presentation Complete (%s) at %s\n',...
                stopType,datestr(now,13));
            obj.printFcn('execution time %s\n',secs2Str(reqTime));
            releaseEngine(obj.dispatchEngine);
            % If interleaved sequence order, reset number of presentations
            % for all sequences to the original values
            %if strcmp(obj.orderType,'interleaved')
            %    for iS = 1:numel(obj.sequences)
            %        obj.sequences{iS}.nRepeats = obj.sequenceCounts(iS);
            %    end
            %end
            % Completion notification
            notify(obj,'PresentationComplete',...
                notificationEventClass(stopType));
        end
        
        function nSeq = getNSequences(obj)
            % Return the number of sequences that will be shown during a
            % single session
            nSeq = numel(obj.seqOrder);
        end
        
        function setInterstimulusInterval(obj,value)
            obj.interSeqInterval = value;
        end
        
        function setInterSessionInterval(obj,value)
            obj.interSessInterval = value;
        end
        
        function setNoiseCollectionDelay(obj,value)
            obj.delayInterStim = value;
        end
        
        function setNoiseCollectionPeriod(obj,value)
            obj.interStimPeriod = value;
        end
        
    end
    
    methods
        
        function set.sendStimDetailsToTTL(obj,trueOrFalse)
            obj.sendStimDetailsToTTL = logical(trueOrFalse);
        end
        
    end
    
    methods (Access=private)
        
        function updateLogging(obj)
            obj.sendStimDetailsToTTL = obj.ttlInterface.TTLMetaDataEnabled;
        end
        
    end
    
end