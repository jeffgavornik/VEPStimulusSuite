function resolution = suggestTimerPrecision(priorityLevel)

if nargin < 1
    priorityLevel = [];
end

delayTime = 0.001;
trials = 50;

try
    resolution = [];
    calObj = timerCharacterizationObject;
    precisionFound = false;
    if ~isempty(priorityLevel)
        Priority(priorityLevel);
    end
    count = 0;
    while ~precisionFound && delayTime < 0.5
        calObj.checkTimer(delayTime,trials)
        t1 = tic;
        while ~calObj.checkComplete
            if toc(t1)>10
                error('check not complete');
            end
        end
        delta = mean(calObj.deltas);
        fprintf('target = %1.3f delta = %1.3f\n',delayTime,delta);
        drawnow
        if delta < delayTime * 1.1
            precisionFound = true;
        else
            delayTime = delayTime +1e-3;
        end
        count = count + 1;
        if count > 50
            error('too many iterations');
        end
    end
    Priority(0);
    resolution = delayTime;
catch ME
    handleError(ME,false,'Some stupid thing went wrong');
end
if exist('calObj','var')
    delete(calObj);
end


% while ~precisionFound && delayTime < 0.5
%     
%     t1 = GetSecs;
%     pause(delayTime);
%     delta = GetSecs - t1;
%     if delta < 1.05*delayTime
%         precisionFound = true;
%     else
%         delayTime = delayTime * 2;
%     end
%     
% end
% 
% resolution = delayTime;
% 
