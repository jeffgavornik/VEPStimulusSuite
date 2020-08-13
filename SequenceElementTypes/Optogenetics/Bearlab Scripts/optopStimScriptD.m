% Check SRP in VGAT ChR mice

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
novAngle = 135;

laserOffHoldTime = 5;

nPresPerSession = 20;
nSessions = 2;
isi = 15;

ConfigureAnalogOptoStimControl();
powerLevel = 1;

ev = 0;
seqs = {};

% ------------ Fam With Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
power = powerLevel;

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
ev = ev + 1;
laserOn.eventValue = ev;
laserOn.setFunction('AnalogOn',power)

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = laserOffHoldTime;
ev = ev + 1;
laserOff.eventValue = ev;
laserOff.setFunction('AnalogOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
ev = ev + 1;
seoFlip.eventValue = ev;

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop %1.2f',power);
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
ev = ev + 1;
seoFlop.eventValue = ev;

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
ev = ev + 1;
spacer.eventValue = ev;

optoSeq = stimulusSequenceClass(sprintf('OptoSeq %i PL=%1.2f',...
    convert_cw2ccw(angle),power));
optoSeq.addSequenceElements({ laserOn ...
    seoFlip seoFlop seoFlip seoFlop seoFlip seoFlop ...
    seoFlip seoFlop seoFlip seoFlop spacer laserOff });
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;

% ------------ Nov With Laser ----------------------------------
angle = convert_cw2ccw(novAngle);
power = powerLevel;

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
ev = ev + 1;
laserOn.eventValue = ev;
laserOn.setFunction('AnalogOn',power)

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = laserOffHoldTime;
ev = ev + 1;
laserOff.eventValue = ev;
laserOff.setFunction('AnalogOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
ev = ev + 1;
seoFlip.eventValue = ev;

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop %1.2f',power);
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
ev = ev + 1;
seoFlop.eventValue = ev;

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
ev = ev + 1;
spacer.eventValue = ev;

optoSeq = stimulusSequenceClass(sprintf('OptoSeq %i PL=%1.2f',...
    convert_cw2ccw(angle),power));
optoSeq.addSequenceElements({ laserOn ...
    seoFlip seoFlop seoFlip seoFlop seoFlip seoFlop ...
    seoFlip seoFlop seoFlip seoFlop spacer laserOff });
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;


% Create the session manager and execute ----------------------------------
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'random';
smo.setInterSessionInterval(isi); % Time between sessions
smo.setInterstimulusInterval(0); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences(seqs);
smo.startPresentation;
