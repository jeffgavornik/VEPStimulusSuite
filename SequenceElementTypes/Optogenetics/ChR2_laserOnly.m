% Script that demonstrates how to generate sequence elements that turn the
% light on and off while writing event codes over TTL

% Get the screen and make sure it is open
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

% Define parameters for stim creation and calculate the gratings, make
% shared resources and add
sf = 0.05; % spatial freqs. cy/deg
angle = convert_cw2ccw(45);
sharedResources = containers.Map;
[flip,flop] = make_PR_gratings(sf,100);
sharedResources('flip') = Screen('MakeTexture', sio.window,flip);
sharedResources('flop') = Screen('MakeTexture', sio.window,flop);

nPresPerSession = 50;
nSessions = 3;

% ------------------------------------------------------------------------
% Make a sequence were the laser is on during visual stimulus presentation

% Make the laser on and off elements
% On 0.5 sec before visual stimulus, off half second after last element, 5
% seconds rest
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
laserOn.resourceDict = sharedResources;
laserOn.eventValue = 1;
laserOn.setFunction('LaserOn')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 0.5;
laserOff.resourceDict = sharedResources;
laserOff.eventValue = 2;
laserOff.setFunction('LaserOff')

% Create the sequence
optoSeq = stimulusSequenceClass('OptoSeq');
optoSeq.addSequenceElements({...
    laserOn laserOff ...
    });
optoSeq.setNumberOfPresentations(nPresPerSession);

% Create the session manager and execute
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'random';
smo.setInterSessionInterval(15); % Time between sessions
smo.setInterstimulusInterval(15); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences({optoSeq});
smo.startPresentation;
