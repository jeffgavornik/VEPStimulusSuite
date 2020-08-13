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

% Create the shared resource dictionary for the sequence
sharedResources = containers.Map;

% Create the sequence elements
seo1 = sequenceElementClass;
seo1.holdTime = 0.05; % 0.15;
seo1.resourceKey = 'txt_flip';
seo1.resourceDict = sharedResources;
seo1.eventValue = 1;
seo2 = sequenceElementClass;
seo2.holdTime = 0.05; %0.3;
seo2.resourceKey = 'txt_flop';
seo2.resourceDict = sharedResources;
seo2.eventValue = 2;

% Create the sequence
sso = stimulusSequenceClass;
sso.sequenceName = 'test1';
sso.addSequenceElements({seo1 seo2});
% sso.setElementPresentationOrder([1 2 1 2 1 2]);
sso.setRepeatNumber(5);

% Create the sequence elements
seo3 = sequenceElementClass;
seo3.holdTime = 0.5; % 0.15;
seo3.resourceKey = 'txt_flip';
seo3.resourceDict = sharedResources;
seo3.eventValue = 3;
seo4 = sequenceElementClass;
seo4.holdTime = 0.5; %0.3;
seo4.resourceKey = 'txt_flop';
seo4.resourceDict = sharedResources;
seo4.eventValue = 4;

% Create the sequence
sso2 = stimulusSequenceClass;
sso2.sequenceName = 'test2';
sso2.addSequenceElements({seo3 seo4});
% sso.setElementPresentationOrder([1 2 1 2 1 2]);
sso2.setRepeatNumber(2);

% Open the screen and create textures
sio = screenInterfaceClass.returnInterface;
sio.openScreen;
sharedResources('txt_flip') = Screen('MakeTexture', sio.window,127.5*(1+flip));
sharedResources('txt_flop') = Screen('MakeTexture', sio.window,127.5*(1+flop));

% sio.setGammaCorrection(1.8);

% Listen for sequence completion and close the screen
%addlistener(sso,'SequenceComplete',@(src,event)closeScreen(sio));

% Tell the dispatch engine to show the stim flip times
% sdeo.recordFlipTimes();

% Start the sequence
% sdeo.loadSequence(sso);
% sdeo.startSequence;
% sdeo.loadSequence(sso2);
% sdeo.startSequence;

% Create a session manager
smo = startleSessionManagerClass;
% smo = sessionManagerClass;
% smo.provideSCASupport();
smo.setInterstimulusInterval(120);
smo.addSequences({sso sso2});
smo.setNumberOfSessions(5);
smo.setOrderType('random');
smo.startPresentation;


