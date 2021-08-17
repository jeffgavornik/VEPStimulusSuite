% Script to trigger pulses using the arduio serial interface


aso = arduinoSerialPulseGenerator;
aso.burstDuration = 500;
aso.pulseFreq = 100;
aso.dutyCycle = 100;
aso.showReceivedSerialData = false;
interPulseInterval = 2;

totalTime = 60*60*72; % secs
startTime = GetSecs;
stopTime = startTime + totalTime;
keepRunning = true;
pulseCount = 0;
while keepRunning
    if GetSecs > stopTime
        keepRunning = false;
    else
        aso.triggerPulse;
        while ~aso.burstActive
            drawnow
        end
        while aso.burstActive
            drawnow
        end
        pulseCount = pulseCount + 1;
        disp(pulseCount);
        WaitSecs(interPulseInterval);
    end
    [ keyIsDown, timeSecs, keyCode ] = KbCheck;
    if keyIsDown && find(keyCode,1) == KbName('ESCAPE')
        keepRunning = false;
    end
end

fprintf('%i pulses delivered over %s\n',pulseCount,secs2Str(GetSecs - startTime));