% Test screenInterfaceObject

% Define parameters for stim creation -------------------------------------

deg = 45; % degrees
con = 100; % contrast
sf = 0.05; % spatial freqs (cy/deg)
md = 0.160; % distance to monitor
MonitorHeight = 0.302; % meters
MonitorWidth = 0.405; % meters

% Set monitor resolution
cols = 1280;
rows = 1024;

% -------------------------------------------------------------------------

% Set up spatial aspect of stimulus
wH = rows;
wW = cols;
[x,y] = meshgrid((1:wW)-floor(wW/2), (1:wH)-floor(wH/2));

% Calculate spatial periods in pixels for x and y dimensions
Dy = sf * 2* 180 * atan(MonitorHeight/md) / (md * pi * rows);
Dx = sf * 2* 180 * atan(MonitorWidth/md) / (md * pi * cols);

% Generate full screen grating
theta = pi*deg/180;
flip = (con/100)*sin(Dx*x*sin(theta) + Dy*y*cos(theta));
flop = (con/100)*sin(Dx*x*sin(theta) + Dy*y*cos(theta) + pi);


% Create the interface and do a few scheduled flip/flops
sco = screenInterfaceClass.returnInterface;

try
    sco.openScreen;
    
    % Make textures from image matrici
    screenNumber=max(Screen('Screens'));
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);
    gray = (white+black)/2;
    inc = white-gray;
    ti(1)=Screen('MakeTexture', sco.window, gray + flip*inc);
    ti(2)=Screen('MakeTexture', sco.window, gray + flop*inc);
    ti(3)=Screen('MakeTexture', sco.window, gray * ones(size(flip)));
    
    Screen('DrawTexture',sco.window,ti(1),[],[],90);
    vbl = Screen('flip');
    Screen('DrawTexture',sco.window,ti(2),[],[],90);
    sco.scheduleFlipRelativeToVBL(0.5);
    
    WaitSecs(5);
    sco.closeScreen;
catch ME
    fprintf('screenInterfaceClass error: \nReport\n%s',getReport(ME));
    Screen('CloseAll');
end

sco.deleteInterface();
