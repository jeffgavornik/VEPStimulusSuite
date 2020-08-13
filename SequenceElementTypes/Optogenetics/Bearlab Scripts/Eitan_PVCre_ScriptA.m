% Look for SRP modulated vidget in PV-Cre mice expressing ChR in V1
%
% Show fam and nov angles with and without laser turned on
% Assumes analog 

%#ok<*SAGROW,*NASGU>

% -------------------------------------------------------------------------
% ---------------- Set Stimulus Parameters --------------------------------

famAngle = 15;
novAngle = 135;

AnalogOffHoldTime = 5; % Hold time after the laser turns off
flipFlopsPerPres = 10; % Contiguous flip-flop pairs per presentation
nPresPerSession = 10; % Presentations per session for each condition
nSessions = 1; % Number of sessions
isi = 20; % Time between presentations

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

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

% Set isi to be true gray period
isi = isi-AnalogOffHoldTime;

ConfigureAnalogOptoStimControl(false);
powerLevel = 1;

seqs = {};

% ------------ Fam With Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
power = powerLevel;
evs = 1:5;

AnalogOn = optostimElementClass;
AnalogOn.ID = 'Laser On';
AnalogOn.holdTime = 0.5;
AnalogOn.eventValue = evs(1);
AnalogOn.setFunction('AnalogOn',power)

AnalogOff = optostimElementClass;
AnalogOff.ID = 'Laser Off';
AnalogOff.holdTime = AnalogOffHoldTime;
AnalogOff.eventValue = evs(2);
AnalogOff.setFunction('AnalogOff')

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
seqElmnts = { AnalogOn };
for iS = 1:flipFlopsPerPres
    seqElmnts(end+[1 2]) = {seoFlip,seoFlop}; 
end
seqElmnts(end+[1 2]) = { spacer AnalogOff };
optoSeq.addSequenceElements(seqElmnts);
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;

% ------------ Fam Without Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
power = 0;
evs = 6:10;

AnalogOn = optostimElementClass;
AnalogOn.ID = 'Laser On';
AnalogOn.holdTime = 0.5;
AnalogOn.eventValue = evs(1);
AnalogOn.setFunction('AnalogOn',power)

AnalogOff = optostimElementClass;
AnalogOff.ID = 'Laser Off';
AnalogOff.holdTime = AnalogOffHoldTime;
AnalogOff.eventValue = evs(2);
AnalogOff.setFunction('AnalogOff')

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
seqElmnts = { AnalogOn };
for iS = 1:flipFlopsPerPres
    seqElmnts(end+[1 2]) = {seoFlip,seoFlop};
end
seqElmnts(end+[1 2]) = { spacer AnalogOff };
optoSeq.addSequenceElements(seqElmnts);
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;

% ------------ Nov With Laser ----------------------------------
angle = convert_cw2ccw(novAngle);
power = powerLevel;
evs = 11:15;

AnalogOn = optostimElementClass;
AnalogOn.ID = 'Laser On';
AnalogOn.holdTime = 0.5;
AnalogOn.eventValue = evs(1);
AnalogOn.setFunction('AnalogOn',power)

AnalogOff = optostimElementClass;
AnalogOff.ID = 'Laser Off';
AnalogOff.holdTime = AnalogOffHoldTime;
AnalogOff.eventValue = evs(2);
AnalogOff.setFunction('AnalogOff')

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
seqElmnts = { AnalogOn };
for iS = 1:flipFlopsPerPres
    seqElmnts(end+[1 2]) = {seoFlip,seoFlop};
end
seqElmnts(end+[1 2]) = { spacer AnalogOff };
optoSeq.addSequenceElements(seqElmnts);
optoSeq.setNumberOfPresentations(nPresPerSession);
seqs{end+1} = optoSeq;

% ------------ Fam Without Laser ----------------------------------
angle = convert_cw2ccw(novAngle);
power = 0;
evs = 16:20;

AnalogOn = optostimElementClass;
AnalogOn.ID = 'Laser On';
AnalogOn.holdTime = 0.5;
AnalogOn.eventValue = evs(1);
AnalogOn.setFunction('AnalogOn',power)

AnalogOff = optostimElementClass;
AnalogOff.ID = 'Laser Off';
AnalogOff.holdTime = AnalogOffHoldTime;
AnalogOff.eventValue = evs(2);
AnalogOff.setFunction('AnalogOff')

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
seqElmnts = { AnalogOn };
for iS = 1:flipFlopsPerPres
    seqElmnts(end+[1 2]) = {seoFlip,seoFlop};
end
seqElmnts(end+[1 2]) = { spacer AnalogOff };
optoSeq.addSequenceElements(seqElmnts);
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
