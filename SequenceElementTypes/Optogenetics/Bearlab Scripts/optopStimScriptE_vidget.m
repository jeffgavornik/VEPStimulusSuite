% Look for SRP modulated vidget in VGAT ChR mice

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

laserOffHoldTime = 5;

nPresPerSession = 10;
nSessions = 1;
isi = 45-laserOffHoldTime;

ConfigureAnalogOptoStimControl(false);
powerLevel = 1; % 3/5;

seqs = {};

% ------------ Fam With Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
power = powerLevel;
evs = 1:5;

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
laserOn.eventValue = evs(1);
laserOn.setFunction('AnalogOn',power)

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = laserOffHoldTime;
laserOff.eventValue = evs(2);
laserOff.setFunction('AnalogOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop %1.2f',power);
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
seoFlop.eventValue = evs(4);

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
spacer.eventValue = evs(5);

optoSeq = stimulusSequenceClass(sprintf('OptoSeq %i PL=%1.2f',...
    convert_cw2ccw(angle),power));
optoSeq.addSequenceElements({ laserOn ...
    seoFlip seoFlop seoFlip seoFlop seoFlip seoFlop ...
    seoFlip seoFlop seoFlip seoFlop spacer laserOff });
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;

% ------------ Fam Without Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
power = 0;
evs = 6:10;

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
laserOn.eventValue = evs(1);
laserOn.setFunction('AnalogOn',power)

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = laserOffHoldTime;
laserOff.eventValue = evs(2);
laserOff.setFunction('AnalogOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop %1.2f',power);
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
seoFlop.eventValue = evs(4);

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
spacer.eventValue = evs(5);

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
evs = 11:15;

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
laserOn.eventValue = evs(1);
laserOn.setFunction('AnalogOn',power)

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = laserOffHoldTime;
laserOff.eventValue = evs(2);
laserOff.setFunction('AnalogOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop %1.2f',power);
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
seoFlop.eventValue = evs(4);

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
spacer.eventValue = evs(5);

optoSeq = stimulusSequenceClass(sprintf('OptoSeq %i PL=%1.2f',...
    convert_cw2ccw(angle),power));
optoSeq.addSequenceElements({ laserOn ...
    seoFlip seoFlop seoFlip seoFlop seoFlip seoFlop ...
    seoFlip seoFlop seoFlip seoFlop spacer laserOff });
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;

% ------------ Fam Without Laser ----------------------------------
angle = convert_cw2ccw(novAngle);
power = 0;
evs = 16:20;

laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.5;
laserOn.eventValue = evs(1);
laserOn.setFunction('AnalogOn',power)

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = laserOffHoldTime;
laserOff.eventValue = evs(2);
laserOff.setFunction('AnalogOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop %1.2f',power);
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
seoFlop.eventValue = evs(4);

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
spacer.eventValue = evs(5);

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
smo.orderType = 'fullyinterleaved';
smo.setInterSessionInterval(isi); % Time between sessions
smo.setInterstimulusInterval(isi); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences(seqs);
smo.startPresentation;
