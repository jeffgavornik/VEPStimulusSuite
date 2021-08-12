% test latency of serial commands sent to the arduino

aso = arduinoSerialPulseGenerator;
if ~aso.validateInterface
    aso.openConnection;
end
aso.showReceivedSerialData = false;
aso.setDataCallback('off');

nTrials = 10000;

t01 = GetSecs();
dummyTimes = zeros(1,nTrials);
for ii = 1:nTrials
    dummyTimes(ii) = GetSecs;
end
t02 = GetSecs;
loopTime = t02-t01;

times = zeros(1,nTrials);
t1 = GetSecs;
for ii = 1:nTrials
    aso.triggerPulse;
    times(ii) = GetSecs;
end
t2 = times(end);
tTotal = t2-t1;
avg = tTotal/nTrials;
avgCorr = (tTotal-loopTime)/nTrials;
fprintf('Total loop time for %i trials = %1.2f sec\n',nTrials,tTotal);
fprintf('  Avg loop time = %1.3f ms\n',avg*1000);
fprintf('  Avg corrected time (e.g. Serial command time) = %1.3f ms\n',avgCorr*1000);

aso.setDataCallback('on');
