% Draw a gray screen.  Strobe a specified event value at a specified rate
% for a specified duration

% User configurable parameters
totalDurationInMins = 30; % minutes
strobePeriod = 0.5; % seconds
eventValue = 0; % values to set

if ~ScrnCtrlApp('requestSynchronousScreenControl')
    error('ScrnCtrlApp not releasing control');
end
sio = screenInterfaceClass.returnInterface;
sio.openScreen;
win = sio.getWindow;
ttl = ttlInterfaceClass.getTTLInterface;
userAbort = false;
try
    totalDurationInSecs = 60*totalDurationInMins;
    scaPrintf('Will strobe event %i for the next %s',eventValue,...
        secs2Str(totalDurationInSecs));
    scaPrintf('Will be done at %s',datestr(now+seconds(totalDurationInSecs),13));
    ttl.startRecording;
    Screen('FillRect',win,sio.monProfile.gray * [1 1 1]);
    vbl = sio.flipScreen();
    startTime = vbl;
    now = vbl;
    while now-startTime < totalDurationInSecs
        now = GetSecs;
        if now-vbl>strobePeriod-sio.slack
            vbl = sio.flipScreen();
            ttl.strobeEventWord(eventValue);
        end
        if ScrnCtrlApp('checkUserAbort')
            userAbort = true;
            error('user abort');
        end
        drawnow limitrate;
    end
    scaPrintf('Script complete');
catch ME %#ok<NASGU>
    if userAbort
        scaPrintf('User Abort');
    else
        handleError(ME,false,'Script Error');
    end
end
ttl.stopRecording;
sio.flipScreen;
ScrnCtrlApp('releaseSynchronousScreenControl');