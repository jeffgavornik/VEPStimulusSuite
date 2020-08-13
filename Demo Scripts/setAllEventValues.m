% Script to help Cookiepuss troubleshoot his omniplex.  Press any keyboard
% button to abort script in the middle of execution
%#ok<*UNRCH>

% User configurable parameters
delta = 0.05; % wait time between event values
eventValues = 0:255; % values to set
strobeValues = false; 

% Do the actual work
ttl = ttlInterfaceClass.getTTLInterface;
nEv = length(eventValues);
iE = 1;
needsUpdate = true;
active = true;
lastTime = GetSecs;
WaitSecs(0.25); % don't trigger abort if command line used to initiate script
while active
    if needsUpdate
        iE = iE + 1;
        if strobeValues
            ttl.strobeEventWord(eventValues(iE));
        else
            ttl.setEventWord(eventValues(iE));
        end
        needsUpdate = false;
    end
    now = GetSecs;
    if now - lastTime >= delta
        if iE+1 > nEv
            active = false;
        end
        lastTime = now;
        needsUpdate = true;
    end
    if KbCheck % user abort on keyboard press
        active = false;
    end
    drawnow
end
fprintf('Script Complete\n');
% web('https://youtu.be/7uhIxyTQRkY');