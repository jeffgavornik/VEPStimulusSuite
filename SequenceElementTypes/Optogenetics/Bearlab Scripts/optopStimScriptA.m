ConfigureDigitalOptoStimControl();

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

nPresPerSession = 20;
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
laserOff.holdTime = 10;
laserOff.resourceDict = sharedResources;
laserOff.eventValue = 2;
laserOff.setFunction('LaserOff')

% Make the visual only elements - uniquely number events so that it is easy
% to see if the inhibition loses efficacy over time
seoFlip1 = sequenceElementClass;
seoFlip1.ID = 'Flip1';
seoFlip1.holdTime = 0.5;
seoFlip1.rotation = angle;
seoFlip1.resourceKey = 'flip';
seoFlip1.resourceDict = sharedResources;
seoFlip1.eventValue = 3;

seoFlop1 = sequenceElementClass;
seoFlop1.ID = 'Flop1';
seoFlop1.holdTime = 0.5;
seoFlop1.rotation = angle;
seoFlop1.resourceKey = 'flop';
seoFlop1.resourceDict = sharedResources;
seoFlop1.eventValue = 4;

seoFlip2 = sequenceElementClass;
seoFlip2.ID = 'Flip2';
seoFlip2.holdTime = 0.5;
seoFlip2.rotation = angle;
seoFlip2.resourceKey = 'flip';
seoFlip2.resourceDict = sharedResources;
seoFlip2.eventValue = 5;

seoFlop2 = sequenceElementClass;
seoFlop2.ID = 'Flop2';
seoFlop2.holdTime = 0.5;
seoFlop2.rotation = angle;
seoFlop2.resourceKey = 'flop';
seoFlop2.resourceDict = sharedResources;
seoFlop2.eventValue = 6;

seoFlip3 = sequenceElementClass;
seoFlip3.ID = 'Flip3';
seoFlip3.holdTime = 0.5;
seoFlip3.rotation = angle;
seoFlip3.resourceKey = 'flip';
seoFlip3.resourceDict = sharedResources;
seoFlip3.eventValue = 7;

seoFlop3 = sequenceElementClass;
seoFlop3.ID = 'Flop3';
seoFlop3.holdTime = 0.5;
seoFlop3.rotation = angle;
seoFlop3.resourceKey = 'flop';
seoFlop3.resourceDict = sharedResources;
seoFlop3.eventValue = 8;

seoFlip4 = sequenceElementClass;
seoFlip4.ID = 'Flip4';
seoFlip4.holdTime = 0.5;
seoFlip4.rotation = angle;
seoFlip4.resourceKey = 'flip';
seoFlip4.resourceDict = sharedResources;
seoFlip4.eventValue = 9;

seoFlop4 = sequenceElementClass;
seoFlop4.ID = 'Flop4';
seoFlop4.holdTime = 0.5;
seoFlop4.rotation = angle;
seoFlop4.resourceKey = 'flop';
seoFlop4.resourceDict = sharedResources;
seoFlop4.eventValue = 10;

seoFlip5 = sequenceElementClass;
seoFlip5.ID = 'Flip5';
seoFlip5.holdTime = 0.5;
seoFlip5.rotation = angle;
seoFlip5.resourceKey = 'flip';
seoFlip5.resourceDict = sharedResources;
seoFlip5.eventValue = 11;

seoFlop5 = sequenceElementClass;
seoFlop5.ID = 'Flop5';
seoFlop5.holdTime = 0.5;
seoFlop5.rotation = angle;
seoFlop5.resourceKey = 'flop';
seoFlop5.resourceDict = sharedResources;
seoFlop5.eventValue = 12;

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
spacer.eventValue = 13;

% Create the sequence
optoSeq = stimulusSequenceClass('OptoSeq');
optoSeq.addSequenceElements({...
    laserOn ...
    seoFlip1 seoFlop1 ...
    seoFlip2 seoFlop2 ...
    seoFlip3 seoFlop3 ...
    seoFlip4 seoFlop4 ...
    seoFlip5 seoFlop5 ...
    spacer ...
    laserOff ...
    });
optoSeq.setNumberOfPresentations(nPresPerSession);

% ------------------------------------------------------------------------
% Make a sequence were the laser is off during visual stimulus presentation

laserOn2 = optostimElementClass;
laserOn2.ID = 'Laser Fake On';
laserOn2.holdTime = 0.5;
laserOn2.resourceDict = sharedResources;
laserOn2.eventValue = 14;
laserOn2.setFunction('LaserOff')

laserOff2 = optostimElementClass;
laserOff2.ID = 'Laser Fake Off';
laserOff2.holdTime = 10;
laserOff2.resourceDict = sharedResources;
laserOff2.eventValue = 15;
laserOff2.setFunction('LaserOff')

seoFlip6 = sequenceElementClass;
seoFlip6.ID = 'Flip6';
seoFlip6.holdTime = 0.5;
seoFlip6.rotation = angle;
seoFlip6.resourceKey = 'flip';
seoFlip6.resourceDict = sharedResources;
seoFlip6.eventValue = 16;

seoFlop6 = sequenceElementClass;
seoFlop6.ID = 'Flop6';
seoFlop6.holdTime = 0.5;
seoFlop6.rotation = angle;
seoFlop6.resourceKey = 'flop';
seoFlop6.resourceDict = sharedResources;
seoFlop6.eventValue = 17;

seoFlip7 = sequenceElementClass;
seoFlip7.ID = 'Flip7';
seoFlip7.holdTime = 0.5;
seoFlip7.rotation = angle;
seoFlip7.resourceKey = 'flip';
seoFlip7.resourceDict = sharedResources;
seoFlip7.eventValue = 18;

seoFlop7 = sequenceElementClass;
seoFlop7.ID = 'Flop7';
seoFlop7.holdTime = 0.5;
seoFlop7.rotation = angle;
seoFlop7.resourceKey = 'flop';
seoFlop7.resourceDict = sharedResources;
seoFlop7.eventValue = 19;

seoFlip8 = sequenceElementClass;
seoFlip8.ID = 'Flip8';
seoFlip8.holdTime = 0.5;
seoFlip8.rotation = angle;
seoFlip8.resourceKey = 'flip';
seoFlip8.resourceDict = sharedResources;
seoFlip8.eventValue = 20;

seoFlop8 = sequenceElementClass;
seoFlop8.ID = 'Flop8';
seoFlop8.holdTime = 0.5;
seoFlop8.rotation = angle;
seoFlop8.resourceKey = 'flop';
seoFlop8.resourceDict = sharedResources;
seoFlop8.eventValue = 21;

seoFlip9 = sequenceElementClass;
seoFlip9.ID = 'Flip9';
seoFlip9.holdTime = 0.5;
seoFlip9.rotation = angle;
seoFlip9.resourceKey = 'flip';
seoFlip9.resourceDict = sharedResources;
seoFlip9.eventValue = 22;

seoFlop9 = sequenceElementClass;
seoFlop9.ID = 'Flop9';
seoFlop9.holdTime = 0.5;
seoFlop9.rotation = angle;
seoFlop9.resourceKey = 'flop';
seoFlop9.resourceDict = sharedResources;
seoFlop9.eventValue = 23;

seoFlip10 = sequenceElementClass;
seoFlip10.ID = 'Flip10';
seoFlip10.holdTime = 0.5;
seoFlip10.rotation = angle;
seoFlip10.resourceKey = 'flip';
seoFlip10.resourceDict = sharedResources;
seoFlip10.eventValue = 24;

seoFlop10 = sequenceElementClass;
seoFlop10.ID = 'Flop10';
seoFlop10.holdTime = 0.5;
seoFlop10.rotation = angle;
seoFlop10.resourceKey = 'flop';
seoFlop10.resourceDict = sharedResources;
seoFlop10.eventValue = 25;

spacer2 = sequenceElementClass;
spacer2.ID = 'Spacer2';
spacer2.holdTime = 0.5;
spacer2.eventValue = 26;

noOptoSeq = stimulusSequenceClass('NoOptoSeq');
noOptoSeq.addSequenceElements({...
    laserOn2 ...
    seoFlip6 seoFlop6 ...
    seoFlip7 seoFlop7 ...
    seoFlip8 seoFlop8 ...
    seoFlip9 seoFlop9 ...
    seoFlip10 seoFlop10 ...
    spacer2 ...
    laserOff2 ...
    });
noOptoSeq.setNumberOfPresentations(nPresPerSession);

% Create the session manager and execute
smo = sessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'random';
smo.setInterSessionInterval(15); % Time between sessions
smo.setInterstimulusInterval(15); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences({optoSeq noOptoSeq});
smo.startPresentation;
