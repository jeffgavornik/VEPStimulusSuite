function getLuminenceRatios

daq = daqInterfaceClass.getDAQInterface;
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

grayLum = 0;
blackLum = 0;
whiteLum = 0;
nSample = 10;
for ii = 1:nSample
    sio.setBackgroundColor('black');
    WaitSecs(0.1);
    blackLum = blackLum + 5-daq.readAnalogVoltage(0);
    sio.setBackgroundColor('gray');
    WaitSecs(0.1);
    grayLum = grayLum + 5-daq.readAnalogVoltage(0);
    sio.setBackgroundColor('white');
    WaitSecs(0.1);
    whiteLum = whiteLum + 5-daq.readAnalogVoltage(0);
end
blackLum = blackLum / nSample;
grayLum = grayLum / nSample;
whiteLum = whiteLum / nSample;
fprintf('Black Lum = %f, Gray lum = %f, White loom = %f\n',...
    blackLum,grayLum,whiteLum);
fprintf('%f, %f, %f\n',...
    blackLum/grayLum,grayLum/grayLum,whiteLum/grayLum);


cmdValue = 127;
targetGrayLum = blackLum + (whiteLum-blackLum)/2;
delta = grayLum - targetGrayLum;
while abs(delta) > 1e-3 && (cmdValue <= 255 || cmdValue >= 0)
    fprintf('CmdVal = %i: GrayLum = %1.2f, target = %1.2f, delta = %1.2f\n',...
        cmdValue,grayLum,targetGrayLum,delta);
    if delta > 0
        cmdValue = cmdValue - 1;
    else
        cmdValue = cmdValue + 1;
    end
    sio.setBackgroundColor(cmdValue*[1 1 1]);
    WaitSecs(0.01);
    grayLum = 0;
    for ii = 1:20
        grayLum = grayLum + 5-daq.readAnalogVoltage(0);
        WaitSecs(1e-3);
    end
    grayLum = grayLum / 20;
    delta = grayLum - targetGrayLum;
end
fprintf('CmdVal = %i: GrayLum = %1.2f, target = %1.2f, delta = %1.2f\n',...
        cmdValue,grayLum,targetGrayLum,delta);

fprintf('Black Lum = %f, Gray lum = %f, White loom = %f\n',...
    blackLum,grayLum,whiteLum);
fprintf('%f, %f, %f\n',...
    blackLum/grayLum,grayLum/grayLum,whiteLum/grayLum);

% sio.gray = cmdValue;

% fprintf('\nClose to target at  %i\n',cmdValue,ratio);

% 
% cmdValue = -1;
% ratio = blackLum/grayLum;
% while ratio < 0.5
%     cmdValue = cmdValue + 1;
%     sio.setBackgroundColor(cmdValue*[1 1 1]);
%     WaitSecs(0.05);
%     blackLum = 0;
%     for ii = 1:20
%         blackLum = blackLum + 5-daq.readAnalogVoltage(0);
%     end
%     blackLum = blackLum / 20;
%     ratio = blackLum / grayLum;
% end
% fprintf('\nBlack at %1.2f gray for value %i\n',cmdValue,ratio);
% 
% 
% cmdValue = 256;
% ratio = whiteLum/grayLum;
% while ratio > 1.5
%     cmdValue = cmdValue - 1;
%     sio.setBackgroundColor(cmdValue*[1 1 1]);
%     WaitSecs(0.05);
%     whiteLum = 0;
%     for ii = 1:20
%         whiteLum = whiteLum + 5-daq.readAnalogVoltage(0);
%     end
%     whiteLum = whiteLum / 20;
%     ratio = whiteLum/grayLum;
% end
% fprintf('White at 2x gray for value %i\n',cmdValue);