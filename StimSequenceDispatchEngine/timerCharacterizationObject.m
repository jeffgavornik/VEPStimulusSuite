classdef timerCharacterizationObject < handle
    % Used by suggestTimerPrecision() to assess the functional resolution of the matlab timer
    
    properties (SetAccess=private)
        checkComplete
        deltas
    end
    
    properties (Access=private)
        hTimer
        tStart
        trials
        count
    end
    
    methods
        
        function obj = timerCharacterizationObject
            obj.hTimer = timer('Name','CalibrationTimer',...
                'ExecutionMode','fixedRate',...
                'TimerFcn',@(src,evnt)timerCallback(obj));
        end
        
        function delete(obj)
           deleteTimers(obj.hTimer);
        end
        
        function checkTimer(obj,delayTime,trials)
            if nargin < 3 || isempty(trials)
                trials = 1;
            end
            obj.trials = trials;
            obj.deltas = zeros(1,trials);
            obj.checkComplete = false;
            obj.count = 0;
            obj.hTimer.StartDelay = delayTime;
            obj.startTheTimer;
        end
        
        function startTheTimer(obj)
            obj.tStart = GetSecs;
            obj.count = obj.count + 1;
            start(obj.hTimer);
        end
        
        function timerCallback(obj)
            rightNow = GetSecs;
            stop(obj.hTimer);
            obj.deltas(obj.count) = rightNow - obj.tStart;
            if obj.count == obj.trials
                obj.checkComplete = true;
            else
                obj.startTheTimer;
            end
        end
            
    end
end