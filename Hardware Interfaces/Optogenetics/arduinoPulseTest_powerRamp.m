% Pulse laser while ramping duty cycle


aso = arduinoSerialPulseGenerator;
aso.showReceivedSerialData = true;
aso.burstDuration = 0;
aso.pulseFreq = 10;
aso.triggerPulse;

dutyCycles = [0:1:100,100:-1:0];
for dutyCycle = dutyCycles
    aso.dutyCycle = dutyCycle;
    WaitSecs(0.1);
end
aso.abortPulse;
aso.showReceivedSerialData = true;