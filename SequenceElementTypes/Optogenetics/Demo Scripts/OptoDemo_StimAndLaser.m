% Script that demonstrates how to generate sequence elements that turn the
% light on and off while rendering gratings and writing event codes over TTL

% Get the screen and make sure it is open
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

% Define parameters for stim creation and calculate the gratings, make
% shared resources and add
sf = 0.05; % spatial freqs. cy/deg
sharedResources = containers.Map;
[flip,flop] = make_PR_gratings(sf,100);
sharedResources('flip') = Screen('MakeTexture', sio.window,flip);
sharedResources('flop') = Screen('MakeTexture', sio.window,flop);

famAngle = 45;
novAngle = 15;

nPresPerSession = 20;
nSessions = 2;
isi = 15;

restTimeBetweenLight = 5;

seqs = {};

% ------------ Stim With Laser ----------------------------------
angle = convert_cw2ccw(famAngle);

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
ev = 1;
laserOn.eventValue = ev;
laserOn.setFunction('LaserOn')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = restTimeBetweenLight;
ev = 2;
laserOff.eventValue = ev;
laserOff.setFunction('LaserOff')

seoFlip = optostimElementClass;
seoFlip.ID = sprintf('Flip with Laser');
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
ev = 3;
seoFlip.eventValue = ev;
seoFlip.setFunction('LaserOn')

seoFlop = optostimElementClass;
seoFlip.ID = sprintf('Flop without Laser');
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
ev = 4;
seoFlop.eventValue = ev;
seoFlop.setFunction('LaserOff')

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
ev = 5;
spacer.eventValue = ev;

optoSeq = stimulusSequenceClass('With Laser');
optoSeq.addSequenceElements({ ...
    seoFlip seoFlop seoFlip seoFlop seoFlip seoFlop ...
    seoFlip seoFlop seoFlip spacer laserOn laserOff });
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;


% Create the session manager and execute ----------------------------------
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'fullyinterleaved';
smo.setInterSessionInterval(isi); % Time between sessions
smo.setInterstimulusInterval(0); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences(seqs);
smo.startPresentation;
