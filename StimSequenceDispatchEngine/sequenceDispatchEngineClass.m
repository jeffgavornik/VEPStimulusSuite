classdef sequenceDispatchEngineClass < singletonClass
    
    % Object class that is used to schedule stimulusSequenceClass drawing
    % events.  Requires support from a screenInterfaceObject and provides
    % scheduling of sequences across sessions
    
    % Note: the lowResFlipTimer is used to get "close" to the desired flip
    % time at which point the high-resolution Psychtoolbox timing engine is
    % used.  Although it is basically a single-shot operation, the timer
    % scheduling logic results in a situation where the timer callback
    % function doesn't return until after the timer has been rescheduled.
    % In singleshot mode, this return will stop the timer which results in
    % an execution stall.  To prevent this, the timer is setup with
    % the fixedRate execution mode and manually stopped when appropriate.
    
    properties (Constant)
        % defines how close "close" is
        % Note this has to be large enough to account for all of the
        % overhead associated with using the dispatch engine, not just the
        % precision of the timer itself
        defaultLowResTimerAccuracy = 5e-2;
    end
    
    properties (Hidden=true)
        % Provide optional support to store and return flip times
        % Call obj.recordFlipTimes to use
        saveVBLTimes
        cmdFlipTimes
        vblTimes
        vblCounter
    end
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'sequenceDispatchEngineClass';
    end
    
    properties (Hidden=true)
        % Optional  function handle that will be executed at flip time if
        % it is defined
        flipFnc
        % Provide support for drawing every frame (needed for smooth
        % drifting gratings, for example).  When set, the stobe will not
        % fire every time a flip is executed, flips will occur
        % asynchronously and VBL time stamping will be based on the GetSecs
        % function.  This can be set explicitly but best practice is to
        % enable support via the enableFrameRateEventSupport method.
        % Support is automatically disabled when a sequence completes.
        frameRateEvents
        % Delays less than the lowResTimerAccuracy will be sent to Screen
        % immediately.  Greater will use the low res timer.  This parameter
        % is reset everytime the engine is released
        lowResTimerAccuracy
    end
    
    properties (Access=private)
        % Objects that define the screen interface and stim sequence
        sio % screen interface object
        sso % the current stimulus sequence object
        ttlInterface % used to send TTL pulses
        
        scaSupport % interface with the ScrnCrtlApp        
        printFcn % function handle for print statements
        
        % Variables used to schedule flip commands
        lowResFlipTimer
        vbl
        ifi
        nextFlipTime % scheduled flip time
        
        % Event listeners
        sequenceCompletingListener
        sequenceCompleteListener
        
        % Logic flags
        locked % prevent simultaneous use
        ReadyForCloseout
        FlipScheduled
  
    end
    
    events
        ScreenFlip
    end
    
    methods (Static)
        % Define an interface that will insure a single instance of the
        % sequenceDispatchEngineClass exists at one time
        
        function sdeo = getEngine(forceObjRtrn)
            % Return the sequenceDispatchEngineClass object
            % If forceObjRtrn is true, will return the object even if it is locked
            % by some other process.  If forceObjRtrn is false (or not specified)
            % and the object is locked the user will be prompted to
            % override the lock.  If the user chooses not to override, sdeo
            % will be returned as an empty array
            sdeo = [];
            try %#ok<TRYNC>
                userData = get(0,'UserData');
                sdeo = userData(sequenceDispatchEngineClass.singletonDesignatorKey);
            end
            if isempty(sdeo)
                sdeo = sequenceDispatchEngineClass;
            end
            if nargin == 0
                if sdeo.locked
                    prompt = sprintf('Override %s lock?',class(sdeo));
                    selection = questdlg(prompt,...
                        ['Unlock ' class(sdeo)],...
                        'Yes','No','Yes');
                    forceObjRtrn = strcmp(selection,'Yes');
                else
                    forceObjRtrn = false;
                end
            end
            if forceObjRtrn
                sdeo.locked = false;
            end
            if sdeo.locked
                fprintf(2,'sequenceDispatchEngineClass is locked!\n');
                sdeo = [];
            end
        end
        
        function unlockInterface
            sdeo = sequenceDispatchEngineClass.getEngine(true);
            sdeo.locked = false;
        end
        
    end
    
    methods (Access=private)
        % Private access to the constructor gaurantees that the static
        % getEngine method is used, including a check for lock state
        
        function obj = sequenceDispatchEngineClass
            if obj.singletonNeedsConstruction
                obj.sio = screenInterfaceClass.returnInterface;
                obj.ttlInterface = ttlInterfaceClass.getTTLInterface;
                %obj.lowResFlipTimer = [];
                obj.saveVBLTimes = false;
                obj.vblTimes = [];
                obj.cmdFlipTimes = [];
                obj.vblCounter = 0;
                obj.locked = false;
                obj.printFcn = @fprintf;
                obj.scaSupport = false;
                obj.flipFnc = [];
                obj.ReadyForCloseout = false;
                obj.FlipScheduled = false;
                obj.frameRateEvents = false;
                obj.lowResTimerAccuracy = obj.defaultLowResTimerAccuracy;
                obj.lowResFlipTimer = timer('Name','LowResFlip',...
                    'ExecutionMode','fixedRate');
                obj.lowResFlipTimer.TimerFcn = ...
                    @(src,event)executeScheduledFlip_Callback(obj);
            end
        end
    end
    
    methods
        
        function delete(obj)
            deleteTimers(obj.lowResFlipTimer);
            delete(obj.sequenceCompletingListener);
        end
    
        % Allow exculsive use of the engine
        function siezeEngine(obj)
            obj.locked = true;
        end
        
        function releaseEngine(obj)
            obj.locked = false;
            % Reset default timer performance parameter if it has been
            % reset
            obj.lowResTimerAccuracy = obj.defaultLowResTimerAccuracy;
        end
        
        function locked = isLocked(obj)
            locked = obj.locked;
        end
        
        function provideSCASupport(obj)
            % Interface with the ScrnCtrlApp
            if ~ obj.scaSupport
                obj.scaSupport = true;
                obj.printFcn = @scaPrintf;
            end
        end
        
        function provideEventListeningSupport(obj)
           % Pass all sequence event information to objects that request
           % access.  This can be used to track events relative to video
           % acquisition, for example see mouseTrackerClass
        end
        
        function enableFrameRateEventSupport(obj)
            obj.frameRateEvents = true;
        end
        
        function set.frameRateEvents(obj,val)
            if ~isa(val,'logical') && ~(val == 1 || val == 0)
                error('%s.frameRateEvents must be logical',class(obj))
            else
                obj.frameRateEvents = val;
            end
        end
        
        function loadSequence(obj,sso)
            % Load a stimulusSequenceClass object
            obj.sso = sso;
            if obj.scaSupport
                sso.provideSCASupport
            end
            setDispatchEngine(obj.sso,obj);
            obj.sequenceCompletingListener = ...
                addlistener(sso,'LastElement',...
                @(src,event)sequenceCompleting_Callback(obj));
            obj.sequenceCompleteListener = ...
                addlistener(sso,'SequenceComplete',...
                @(src,event)sequenceCloseout(obj,src));
            if obj.saveVBLTimes
                recordFlipTimes(obj);
            end
        end
        
        function startSequence(obj)
            [~,obj.ifi] = obj.sio.getMonitorRefreshRate(false);
            obj.sio.setHighPriority;
            obj.vbl = obj.sio.flipScreen; % synchronize to VBL
            obj.sso.startSequence;
        end
        
        function sequenceCompleting_Callback(obj)
            if ~obj.FlipScheduled
                sequenceCloseout(obj);
            else
                obj.ReadyForCloseout = true;
            end
        end
        
        function sequenceCloseout(obj,~)
            % This method is called when ReadyForCloseout is true following
            % a flip.  This will occur when the current sequence posts a
            % SequenceComplete event which in turn calls
            % sequenceCompleteting_Callback
            if nargin > 1
                obj.sio.flipScreen;
            end
            % Clean up after a sequence reports itself to be complete
            obj.ReadyForCloseout = false;
            stop(obj.lowResFlipTimer);
            %deleteTimers(obj.lowResFlipTimer);
            %obj.lowResFlipTimer = [];
            obj.sio.setLowPriority;
            obj.sio.flipScreen;
            if obj.saveVBLTimes
                obj.plotVBLTimes();
            end
            % setEventWord(obj.ttlInterface,0); % Make sure event value is not preserved
            completedSequence = obj.sso;
            obj.sso = [];
            delete(obj.sequenceCompleteListener);
            delete(obj.sequenceCompletingListener);
            obj.sequenceCompletingListener = [];
            obj.sequenceCompleteListener = [];
            notify(completedSequence,'SequenceComplete',...,...
                notificationEventClass('Normal'));
            % Turn off frameRateEvent support if it is enabled
            obj.frameRateEvents = false;
        end
        
        function abortSequence(obj)
            if ~isempty(obj.sso)
                stopSequence(obj.sso);
            end
        end
        
        function scheduleFlipRelativeToVBL(obj,relativeDelay,hFnc)
            %fprintf('%s:scheduleFlipRelativeToVBL(%f)\n',class(obj),relativeDelay);
            % If defined, set the flipFnc
            if ~isempty(hFnc)
                obj.flipFnc = hFnc;
            end
            % Calculate the next flip time and schedule
            if relativeDelay == 0
                obj.nextFlipTime = obj.vbl + 0.95*obj.ifi;
            else
                % if obj.frameRateEvents
                %     dynamicSlack = obj.ifi - mod(relativeDelay,obj.ifi) - 5e-4;
                %     obj.nextFlipTime = obj.vbl + relativeDelay+dynamicSlack;
                % else
                obj.nextFlipTime = obj.vbl + relativeDelay-obj.sio.slack;
                %  end
            end
            % If there is a "lot" of time before the flip, schedule the
            % lowRes timer to get close, otherwise invoke the execute
            % callback immediately
            delayToFlip = obj.nextFlipTime - GetSecs;
            
            %fprintf('%s:scheduleFlipRelativeToVBL delayToFlip = %1.5f\n',class(obj),delayToFlip);
            
            if delayToFlip > obj.lowResTimerAccuracy
                timerDelay = round(delayToFlip - obj.lowResTimerAccuracy,3);
                %fprintf(2,'timerDelay=%1.4f\n',timerDelay);
                set(obj.lowResFlipTimer,'StartDelay',timerDelay);
                % fprintf('timerDelay: %f\n',timerDelay);
                start(obj.lowResFlipTimer);
                obj.FlipScheduled = true;
            else
                obj.executeScheduledFlip_Callback();
            end
        end
        
        function executeScheduledFlip_Callback(obj)
            % delayFlipTimer callback, executes the flip command at the
            % scheduled high-resolution time
            
            %fprintf('%s:executeScheduledFlip_Callback@%1.3f flipSceduled = %i\n',...
            %    class(obj),GetSecs,obj.FlipScheduled);            
            %delayToFlip = obj.nextFlipTime - GetSecs;
            %fprintf('executeScheduledFlip_Callback delayToFlip = %1.5f\n',delayToFlip);            
            if obj.FlipScheduled
                stop(obj.lowResFlipTimer);
            end
            obj.FlipScheduled = false;

            % Execute the flip with high temporal precision
            % Strobe the plxInterface to record the event value - if
            % ReadyForCloseout is set, this means that the current flip
            % command is not associated with a specific
            % sequenceElementClass draw event (case 3 in
            % stimulusSequenceClass.prepNextElement) and strobing will
            % cause an extraneous timestamp with the event value of the 
            % last element in the sequence.  Do not strobe in this case.
            % If frameRateEvents is set true, do not strobe at all on flip
            % events and use asynchronous flips to get better performance
            if obj.frameRateEvents
                if obj.ReadyForCloseout
                    %obj.vbl = Screen(obj.sio.window,'Flip', obj.nextFlipTime,0);
                    obj.sio.flipScreen(obj.nextFlipTime,0,1);
                else
                    %obj.vbl = Screen(obj.sio.window,'Flip', obj.nextFlipTime,0,1);
                    obj.sio.flipScreen(obj.nextFlipTime,0,1);
                end
               obj.vbl = GetSecs;
            else
                if obj.ReadyForCloseout
                    %obj.vbl = Screen(obj.sio.window,'Flip', obj.nextFlipTime);
                    obj.vbl = obj.sio.flipScreen(obj.nextFlipTime,0);
                else
                    %obj.vbl = Screen(obj.sio.window,'Flip', obj.nextFlipTime);
                    obj.vbl = obj.sio.flipScreen(obj.nextFlipTime,0);
                    obj.ttlInterface.strobe;
                end
            end
            if obj.vbl > obj.nextFlipTime + 1.5*obj.sio.slack
                str = sprintf('sequenceDispatchEngine: flip just missed target, delta = %f\n',obj.vbl-obj.nextFlipTime);
                handleWarning(str,false,'Timing Warning');
                scaWarning(str);
            end
            % notify(obj,'ScreenFlip');
            
            % If defined, execute the flip function
            if ~isempty(obj.flipFnc)
                obj.flipFnc();
                obj.flipFnc = [];
            end
            if obj.saveVBLTimes
                obj.vblCounter = obj.vblCounter + 1;
                obj.vblTimes(obj.vblCounter) = obj.vbl;
                obj.cmdFlipTimes(obj.vblCounter) = obj.nextFlipTime;
            end
            if obj.ReadyForCloseout
                sequenceCloseout(obj);
            else
                obj.sso.prepNextElement();
            end
        end
        
        function flipNow(obj,hFnc)
            %fprintf('%s:flipNow\n',class(obj));
            % See comment above for logic behind use of ReadyForCloseout
            if obj.ReadyForCloseout
                %obj.vbl = Screen(obj.sio.window,'Flip',0);
                obj.vbl = obj.sio.flipScreen(0,0);
            else
                %obj.vbl = Screen(obj.sio.window,'Flip',0);
                if obj.frameRateEvents
                    obj.sio.flipScreen(obj.nextFlipTime,0,1);
                    obj.vbl = GetSecs;
                else
                    obj.vbl = obj.sio.flipScreen(0,0);
                    strobe(obj.ttlInterface);
                end
            end
            % notify(obj,'ScreenFlip');
            % If defined, execute the flip function
            if ~isempty(hFnc)
                hFnc();
                obj.flipFnc = [];
            end
            obj.nextFlipTime = [];
            if obj.saveVBLTimes
                obj.vblCounter = obj.vblCounter + 1;
                obj.vblTimes(obj.vblCounter) = obj.vbl;
                obj.cmdFlipTimes(obj.vblCounter) = obj.vbl;
            end
            if obj.ReadyForCloseout
                sequenceCloseout(obj);
            else
                obj.sso.prepNextElement();
            end
        end
        
        function ft = getNextFlipTime(obj)
            if isempty(obj.nextFlipTime)
                ft = 0;
            else
                ft = obj.nextFlipTime;
            end
        end
        
        % -----------------------------------------------------------------
        % Methods that provide optional support for saving flip times
        % Used for debugging and performance measures, might or might not
        % be useful generally
        
        function recordFlipTimes(obj)
            % Call this method before executing a sequence to be
            % characterized
            obj.saveVBLTimes = true;
            if ~isempty(obj.sso)
                try
                    nElements = getNElements(obj.sso);
                catch
                    nElements = inf;
                end
                if isfinite(nElements)
                    obj.vblTimes = zeros(1,nElements);
                    obj.cmdFlipTimes = zeros(1,nElements);
                    obj.vblCounter = 0;
                else
                    obj.saveVBLTimes = false;
                end
            end
        end
        
    end
    
    methods (Access=private)
        
        function vblTimes = returnVBLTimes(obj)
            vblTimes = obj.vblTimes;
            obj.saveVBLTimes = false;
            obj.vblCounter = 0;
        end
        
        function plotVBLTimes(obj)
            set(figure,'Name',obj.sso.sequenceName);
            seqElements = 1:numel(obj.vblTimes);
            subplot(3,1,1)
            indZero = obj.cmdFlipTimes == 0;
            obj.cmdFlipTimes(indZero) = obj.vblTimes(indZero);
            timeData.seqElmntNumbers = seqElements(~indZero);
            timeData.deltas = obj.vblTimes(~indZero) - obj.cmdFlipTimes(~indZero);
            plot(timeData.seqElmntNumbers,1e3*timeData.deltas);
            title('Actual - Cmd');
            subplot(3,1,2)
            minTime = min([min(obj.vblTimes(~indZero)) ...
                min(obj.cmdFlipTimes(~indZero))]);
            timeData.vblTimes = obj.vblTimes(~indZero)-minTime;
            timeData.cmdTimes = obj.cmdFlipTimes(~indZero)-minTime;
            plot(timeData.seqElmntNumbers,timeData.vblTimes,'o',...
                timeData.seqElmntNumbers,timeData.cmdTimes,'+');
            legend('vbl','cmd')
            title('Raw Times');
            subplot(3,1,3)
            timeData.onScreenTimes = diff(obj.vblTimes(~indZero));
            plot(timeData.onScreenTimes);
            obj.saveVBLTimes = false;
            title('On screen times')
            % Save results to the base matlab workspace
            assignin('base','sdeoTimeData',timeData);
        end
        
    end
    
    
end