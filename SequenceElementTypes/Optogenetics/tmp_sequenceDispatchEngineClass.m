classdef sequenceDispatchEngineClass < handle
    
    % Object class that is used to schedule stimulusSequenceClass drawing
    % events.  Requires support from a screenInterfaceObject and provides
    % handles scheduling of sequences across sessions
    
    % Note: the lowResFlipTimer is used to get "close" to the desired flip
    % time at which point the high-resolution Psychtoolbox timing engine is
    % used.  Although it is basically a single-shot operation, the timer
    % scheduling logic results in a situation where the timer callback
    % function doesn't return until after the timer has been rescheduled.
    % In singleshot mode, this return will stop the timer which results in
    % an execution stall.  To prevent this, the timer is setup with
    % the fixedRate execution mode and manually stopped when appropriate.
    %
    % March 2014 - Updated for use with singletonObjectClass and for multi
    % monitor support
    
    properties
        
        % Objects that define the screen interface and stim sequence
        sio % screen interface object
        sso % the current stimulus sequence object
        % Variables used to schedule flip commands
        vbl
        nextFlipTime % scheduled flip time
        requestedDelay % delay relative to previous flip time
        
        lowResFlipTimers
        lowResTimerAccuracy % defines how close "close" is
                
        sequenceCompletingListener
        sequenceCompleteListener
        
        ttlInterface % used to send TTL pulses
        flipFnc % optional funciton execution
        % Provide optional support to store and return flip times
        saveVBLTimes
        cmdFlipTimes
        vblTimes
        vblCounter
        
        ReadyForCloseout
        FlipScheduled
                
        locked % prevent simultaneous use
        
        scaSupport % interface with the ScrnCrtlApp        
        printFcn % function handle for print statements
        
        % Provide support for a fixation point
        showFixationPoint
        fpo
        
    end
    
    events
        ScreenFlip
    end
    
    methods (Static)
        % Define an interface that will insure a single instance of the
        % sequenceDispatchEngineClass exists at one time
        
        function removeFromUserData
            % Check to see if an sdeo exists; if so, delete it
            userData = get(0,'UserData');
            if isa(userData,'containers.Map')
                if userData.isKey('sdeo')
                    userData.remove('sdeo');
                end
            end
        end
        
        function addToUserData(obj)
            % Add an hwio to the user data dictionary
            userData = get(0,'UserData');
            if ~isa(userData,'containers.Map')
                userData = containers.Map;
            end
            userData('sdeo') = obj;
            set(0,'UserData',userData)
        end
        
        function exists = checkForExisting
            exists = false;
            userData = get(0,'UserData');
            if isa(userData,'containers.Map')
                if userData.isKey('sdeo')
                    exists = true;
                end
            end
        end
        
        function sdeo = returnObject(force)
            if nargin == 0
                force = false;
            end
            if sequenceDispatchEngineClass.checkForExisting
                userData = get(0,'UserData');
                sdeo = userData('sdeo');
            else
                sdeo = sequenceDispatchEngineClass;
                sequenceDispatchEngineClass.addToUserData(sdeo);
            end
            if ~force
                if sdeo.locked
                    fprintf(2,'sequenceDispatchEngineClass is locked');
                    sdeo = [];
                end
            end
        end
        
        function deleteObject
            if sequenceDispatchEngineClass.checkForExisting
                delete(sequenceDispatchEngineClass.returnObject);
                sequenceDispatchEngineClass.removeFromUserData;
            end
        end
        
        function displayFixationPoint
           sdeo = sequenceDispatchEngineClass.returnObject;
           if ~sdeo.showFixationPoint
               sdeo.fpo = fixationPointClass;
               sdeo.showFixationPoint = true;
               render(sdeo.fpo,sdeo.sio.window);
               Screen(sdeo.sio.window,'Flip');
           end
           
        end
        
        function hideFixationPoint
            sdeo = sequenceDispatchEngineClass.returnObject;
            if sdeo.showFixationPoint
                delete(sdeo.fpo);
                sdeo.fpo = [];
                sdeo.showFixationPoint = false;
                Screen(sdeo.sio.window,'Flip');
                Screen(sdeo.sio.window,'Flip');
            end
        end 
        
    end
    
    methods (Access=private)
        function obj = sequenceDispatchEngineClass
            %fprintf('creating class %s\n',class(obj));
            obj.sio = screenInterfaceClass;
            
            obj.lowResFlipTimers = timer.empty();
            obj.lowResTimerAccuracy = 1e-2;
            obj.saveVBLTimes = false;
            obj.vblTimes = [];
            obj.cmdFlipTimes = [];
            obj.vblCounter = 0;
            obj.locked = false;
            obj.printFcn = @fprintf;
            obj.ttlInterface = ttlInterfaceClass;
            obj.scaSupport = false;
            obj.showFixationPoint = false;
            obj.fpo = false;
            obj.flipFnc = [];
            obj.ReadyForCloseout = false;
            obj.FlipScheduled = false;
            
        end
        
        function delete(obj)
            deleteTimers(obj.lowResFlipTimers);
            delete(obj.sequenceCompletingListener);
        end
    end
    
    methods
           
        % Allow exculsive use of the engine
        function siezeEngine(obj)
            obj.locked = true;
        end
        
        function releaseEngine(obj)
            obj.locked = false;
        end
        
        function provideSCASupport(obj)
            % Interface with the ScrnCtrlApp
            if ~ obj.scaSupport
                obj.scaSupport = true;
                delete(obj.ttlInterface);
                obj.ttlInterface = plxHWInterfaceClass.returnInterface;
                obj.printFcn = @scaPrintf;
            end
        end
        
        function loadSequence(obj,sso)
            % Load a stimulusSequenceClass object
            obj.sso = sso;
            if obj.scaSupport
                sso.provideSCASupport
            end
            setDispatchEngine(obj.sso,obj);
            obj.lowResFlipTimers = timer.empty();
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
        
        function sequenceCompleting_Callback(obj)
            if ~obj.FlipScheduled
                sequenceCloseout(obj);
            else
                obj.ReadyForCloseout = true;
            end
        end
        
        function sequenceCloseout(obj,~)
            if nargin > 1
                Screen(obj.sio.window,'Flip');
            end
            % Clean up after a sequence reports itself to be complete
            obj.ReadyForCloseout = false;
            deleteTimers(obj.lowResFlipTimers);
            obj.lowResFlipTimers = timer.empty();
            obj.sio.setLowPriority;
            if obj.showFixationPoint
                render(obj.fpo,obj.sio.window);
            end
            windows = obj.sio.window;
            for iW = 1:length(windows)
                Screen(windows(iW),'Flip');
            end
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
        end
        
        function abortSequence(obj)
            if ~isempty(obj.sso)
                stopSequence(obj.sso);
            end
        end
        
        function startSequence(obj)
            obj.sio.setHighPriority;
            obj.sso.startSequence;
        end
        
        function scheduleFlipRelativeToVBL(obj,relativeDelay,...
                flipFnc,windows,vbl,lastElmnt)
            %fprintf('%s:scheduleFlipRelativeToVBL(%f)\n',class(obj),relativeDelay);
            
            if nargin < 4 % Backward compatability
                windows = obj.sio.window;
                vbl = [];
                lastElmnt = false;
            end
            
            % Calculate the flip time and schedule
            if isempty(vbl)
                vbl = obj.vbl;
            end
            flipTime = vbl + relativeDelay - obj.sio.slack;
            obj.nextFlipTime = flipTime;
            obj.requestedDelay = relativeDelay;
            
            % If there is a "lot" of time before the flip, schedule the
            % lowRes timer to get close, otherwise invoke the execute
            % callback immediately
            delayToFlip = flipTime - GetSecs;
            if delayToFlip > obj.lowResTimerAccuracy
                timerDelay = double(int8(1e3*(delayToFlip - ...
                    obj.lowResTimerAccuracy)))*1e-3;
                newTimer = timer('ExecutionMode','singleShot',...
                    'StartDelay',timerDelay,'TimerFcn',...
                    @(src,event)executeScheduledFlip_Callback(...
                    obj,src,flipTime,windows,flipFnc,lastElmnt));
                obj.lowResFlipTimers(end+1) = newTimer;
                start(newTimer);
                obj.FlipScheduled = true;
            else
                executeScheduledFlip_Callback(obj,[],flipTime,...
                    windows,flipFnc,lastElmnt);
            end
        end
        
        function executeScheduledFlip_Callback(obj,src,flipTime,...
                windows,flipFnc,lastElmnt)
            %fprintf('%s:executeScheduledFlip_Callback@%f\n',class(obj),GetSecs);
                
            % If src is not empty, than get rid of the timer (src will only
            % be empty if the callback was called without using a timer
            if ~isempty(src)
                stop(src);
                delete(src);
                obj.lowResFlipTimers = obj.lowResFlipTimers(obj.lowResFlipTimers~=src);
                if isempty(obj.lowResFlipTimers)
                    obj.FlipScheduled = false;
                end
            end
            
            % Get windows from the screenInterface if none were specified
            if isempty(windows)
                windows = obj.sio.window;
            end
            nWindows = length(windows);
            
            % Render 
            if obj.showFixationPoint
                render(obj.fpo,windows);
            end
            
            % Execute the flip with high temporal precision
            % Strobe the plxInterface to record the event value - if
            % ReadyForCloseout is set, this means that the current flip
            % command is not associated with a specific
            % sequenceElementClass draw event (case 3 in
            % stimulusSequenceClass.prepNextElement) and strobing will
            % cause an extraneous timestamp with the event value of the
            % last element in the sequence.  Do not strobe in this case.
            if nWindows == 1
                obj.vbl = Screen(windows,'Flip',flipTime,0);
            else
                % Multi Screen case
                Screen('Flip',windows(1),flipTime,0, 1, 0);
                obj.vbl = Screen('Flip', windows(2),flipTime,0, 0, 0);
                
            end
            if ~obj.ReadyForCloseout || ~lastElmnt
                strobe(obj.ttlInterface);
            end
            
            % If defined, execute the flip function
            if ~isempty(flipFnc)
                flipFnc();
            end
            
            % Save metrics
            if obj.saveVBLTimes
                obj.vblCounter = obj.vblCounter + 1;
                obj.vblTimes(obj.vblCounter) = obj.vbl;
                obj.cmdFlipTimes(obj.vblCounter) = obj.nextFlipTime;
            end
            
            % Continue sequence execution
            if obj.ReadyForCloseout || lastElmnt
                sequenceCloseout(obj);
            else
                obj.sso.prepNextElement();
            end
            
        end
        
        function vbl = flipNow(obj,flipFnc,windows,lastElmnt)
            % Execute an immediate flip for all windows.
            
            if nargin == 2
                windows = [];
                lastElmnt = false;
            end
            
            %fprintf('%s:flipNow\n',class(obj));
            if isempty(windows)
                windows = obj.sio.window;
            end            
            nWindows = length(windows);
            
            if obj.showFixationPoint
                render(obj.fpo,obj.sio.window);
            end
            % Execute flip for all windows.  For first n-1, use
            % asynchronous command so as not to wait for completion
            for iW = 1:nWindows-1
                Screen(windows(iW),'Flip',0,0,1,0);
            end
            obj.vbl = Screen(windows(nWindows),'Flip',0);
            vbl = obj.vbl;
            
            if ~obj.ReadyForCloseout || ~lastElmnt
                % See comment above for logic behind use of ReadyForCloseout
                strobe(obj.ttlInterface);
            end
            % If defined, execute the flip function
            if ~isempty(flipFnc)
                flipFnc();
                obj.flipFnc = [];
            end
            obj.nextFlipTime = [];
            if obj.saveVBLTimes
                obj.vblCounter = obj.vblCounter + 1;
                obj.vblTimes(obj.vblCounter) = obj.vbl;
                obj.cmdFlipTimes(obj.vblCounter) = obj.vbl;
            end
            if obj.ReadyForCloseout || lastElmnt
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
        
        function recordFlipTimes(obj)
            obj.saveVBLTimes = true;
            if ~isempty(obj.sso)
                nElements = getNElements(obj.sso);
                if isfinite(nElements)
                    obj.vblTimes = zeros(1,nElements);
                    obj.cmdFlipTimes = zeros(1,nElements);
                    obj.vblCounter = 0;
                else
                    obj.saveVBLTimes = false;
                end
            end
        end
        
        function vblTimes = returnVBLTimes(obj)
            vblTimes = obj.vblTimes;
            obj.saveVBLTimes = false;
            obj.vblCounter = 0;
        end
        
        function plotVBLTimes(obj)
            set(figure,'Name',obj.sso.sequenceName);
            seqElements = 1:numel(obj.vblTimes);
            subplot(3,1,1)
            ind = obj.cmdFlipTimes == 0;
            obj.cmdFlipTimes(ind) = obj.vblTimes(ind);
            plot(seqElements,obj.vblTimes - obj.cmdFlipTimes);
            title('Actual - Cmd');
            subplot(3,1,2)
            minTime = min([min(obj.vblTimes(~ind)) min(obj.cmdFlipTimes(~ind))]);
            plot(seqElements(~ind),obj.vblTimes(~ind)-minTime,'o',...
                seqElements(~ind),obj.cmdFlipTimes(~ind)-minTime,'o');
            legend('vbl','cmd')
            subplot(3,1,3)
            title('On screen times')
            obj.saveVBLTimes = false;
        end
    end
    
end