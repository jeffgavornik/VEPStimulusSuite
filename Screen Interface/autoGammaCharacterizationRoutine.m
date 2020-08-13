function params = autoGammaCharacterizationRoutine
% Function that uses a light meter hooked up to a DAQ device to
% characterize screen
%
% Assumes that the DAQ is correctly configured and hooked up to a light
% metering circuit such that the channel 0 analog voltage will scale
% linearly with screen luminance.  See README for an example circuit that
% can be used with the USB1208FS-Plus
%
% params specify best guess of the gamma value, black and white set
% points and the direct inversion glut

daq = daqInterfaceClass.getDAQInterface;

% pStr = sprintf('autoGammaCharacterizationRoutine assumes a light meter');
% pStr = sprintf('%s is connected to the daq device controlled by the',pStr);
% pStr = sprintf('%s interface with class name %s',pStr,class(daq));
% pStr = sprintf('%s on analog input channel 0',pStr);
% disp(pStr);
% pStr = sprintf('Is the light meter pointed at the screen?');
% disp(pStr);

sio = screenInterfaceClass.returnInterface;
sio.openScreen;

waitTime = 0.1;
nAvgPts = 1;

params = [];
if sio.verifyWindow
    hB = waitbar(0,'Running calibration routine...');
    sio.loadDefaultGammaTable;
    WaitSecs(0.1);
    
    %     % Look for the black set point
    %     sio.setBackgroundColor(0);
    %     WaitSecs(0.1);
    %     v0 = readVoltage(daq,50);
    %     blackRange = 1:20;
    %     for ii = 1:length(blackRange)
    %         sio.setBackgroundColor(blackRange(ii));
    %         WaitSecs(0.2);
    %         v1 = readVoltage(daq,50);
    %         disp([blackRange(ii) v0 v1 abs(v1-v0)]);
    % %         if abs(v1-v0) > 1e-2
    % %             disp('Changed')
    % %         end
    %         v0 = v1;
    %     end
    
    %     sio.setBackgroundColor(255);
    %     WaitSecs(0.5);
    %     Vwhite = 0;
    %     for ii = 1:20
    %         Vwhite = Vwhite + daq.readAnalogVoltage(0);
    %         WaitSecs(0.1);
    %     end
    %     Vwhite = Vwhite/20;
    
    blackSetPoint = sio.black;
    whiteSetPoint = sio.white;
    whiteSetPoint = 250
    
    cmdVals = sio.black:sio.white;
    lumVals = zeros(1,length(cmdVals));
    count = 0;
    totalCount = nAvgPts * 256;
    %     figure;
    %     ylim([Vwhite Vblack])
    %     xlim([0 255])
    %     hold on;
    %     ph = [];
    
    for iA = 1:nAvgPts
        indOrder = randperm(256);
        for iV = 1:length(indOrder)
            ind = indOrder(iV);
            % fprintf('Pass %i or %i: %i of 256\n',iA,nAvgPts,iV);
            sio.setBackgroundColor(cmdVals(ind) * [1 1 1]);
            count = count + 1;
            waitbar(count/totalCount);
            aInVoltage = daq.readAnalogVoltage(0);
            lumVals(ind) = lumVals(ind) + aInVoltage;
            WaitSecs(waitTime);
            %lumVals(ind) = lumVals(ind) + (aInVoltage-Vblack) * Vwhite;
            %             if ~isempty(ph)
            %                 set(ph,'Color',[0 0.4470 0.7410]);
            %             end
            %             ph = plot(cmdVals(ind),aInVoltage,'ro');
            %             drawnow;
        end
    end
    close(hB);
    lumVals = lumVals / nAvgPts;
    lumVals = lumVals(end:-1:1);
    % Fit with 3rd degree polynomial
    cP = polyfit(cmdVals,lumVals,3);
    lumFit = polyval(cP,cmdVals);
    
    figure
    subplot(2,1,1)
    plot(cmdVals,lumVals,cmdVals,lumFit);
    xlim([0 255]);
    xlabel('Command Values')
    ylabel('Voltage');
    title('Auto Gamma Correction')
    
    lvs = lumFit - min(lumFit);
    lvs = lvs / max(lvs); % 0 to 1
    
    % Fit the I/O to a scaled power-law function
    cmdRange = blackSetPoint:whiteSetPoint;
    gammaFnc = @(p,x)p(1)*x.^p(2);
    p0 = [1 2.2];
    pEst = nlinfit(cmdVals,...
        lvs,...
        gammaFnc,p0);
    dataFit = gammaFnc(pEst,cmdRange);
    
    % Invert the function to create the gamma correction with range from 0 to 1
    inverseFnc = @(p,x)x.^(1/p(2));
    correctedData = inverseFnc(pEst,cmdRange);
    gammaTable = correctedData/max(correctedData);
    
    % Perform a direct inversion of the measured points
    xs = (0:255)/255;
    deltas = xs - lvs;
    f1 = xs + deltas;
    f1 = smooth(f1);
    range = cmdVals >= blackSetPoint & cmdVals <= whiteSetPoint;
    glut = interp1(cmdVals(range),f1(range),linspace(blackSetPoint/255,whiteSetPoint/255,256));
    glut = repmat(glut',1,3);
    glut = glut / max(max(glut));
    glut(glut<0) = 0;
    glut(glut>1) = 1;
    
    params.gamma = pEst(2);
    params.wsp = sio.whiteSetPoint;
    params.bsp = sio.blackSetPoint;
    % params.glut = glut;
    params.glut = makeGrayscaleGammaTable(params.gamma,blackSetPoint,whiteSetPoint);
    
    subplot(2,1,2)
    plot(cmdVals,lvs,cmdRange,dataFit,...
        cmdRange,gammaTable,cmdVals,f1);
    xlabel('Command Values')
    ylabel('Luminence (norm)');
    legend('Light Meter Values',sprintf('Fit (gamma=%1.2f)',pEst(2)),...
        'Correction Function','Direct Inverse','Location','Northeastoutside');
    hold on
    plot(linspace(0,255,1000),linspace(0,1,1000),'k--');
    xlim([0 255]);
    ylim([0 1]);
    axis square
    drawnow
end

% glut = makeGrayscaleGammaTable(params.gamma,sio.black,sio.white);
% Screen('LoadNormalizedGammaTable',sio.getWindow,glut);
% notify(sio,'GammaCorrectionApplied');

% function v = readVoltage(daq,samples)
% v = 0;
% for ii = 1:samples
%     v = v + daq.readAnalogVoltage(0);
%     %     WaitSecs(0.005);
% end
% v = v/samples;
