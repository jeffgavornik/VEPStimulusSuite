function monProfile = defaultMonitorProfile
% Return an incorrect default monitor profile structure to allow use of the
% screenInterfaceClass even when the system has not been calibrated
% warning('screenInterfaceClass:Uncalibrated',prompt); %#ok<SPWRN>
monProfile = struct;
monProfile.name = 'DefaultMonitorName';
monProfile.screen_height = 0.30;
monProfile.screen_width = 0.40;
monProfile.viewing_distance = 0.2;
monProfile.number = max(Screen('Screens')); % screen number
resolution = Screen('Resolution',monProfile.number);
monProfile.rows = resolution.height; % pixels
monProfile.cols = resolution.width; % pixels
monProfile.hz = resolution.hz; % refresh rate
monProfile.white = 255; % white value
monProfile.black = 0; % black value
monProfile.gray = 127; % gray value
monProfile.description = ...
    sprintf('DefaultProfile_%ix%i_%iHz',...
    monProfile.rows,monProfile.cols,monProfile.hz);
end