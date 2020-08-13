function deleteTimers(timerObjects)
% Delete timers - if running, stop first
for iT = 1:length(timerObjects)
    theTimer = timerObjects(iT);
    if isa(theTimer,'timer') && ...
            isvalid(theTimer) && strcmp(get(theTimer,'Running'),'on')
        stop(theTimer);
    end
    delete(theTimer)
end