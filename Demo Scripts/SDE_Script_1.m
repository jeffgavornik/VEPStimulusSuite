
%#ok<*SAGROW,*NASGU>

% -------------------------------------------------------------------------
% ---------------- Set Stimulus Parameters --------------------------------

famAngle = 15;
novAngle = 135;

flipFlopsPerPres = 2; % Contiguous flip-flop pairs per presentation
nPresPerSession = 2; % Presentations per session for each condition
nSessions = 2; % Number of sessions
isi = 5; % Time between presentations

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
sharedResources('flip') = sio.makeTexture(flip);
sharedResources('flop') = sio.makeTexture(flop);

seqs = {};

% ------------ Fam Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
evs = 1:5;
power = 0;

AnalogOn = sequenceElementClass;
AnalogOn.ID = 'Laser On';
AnalogOn.holdTime = 0.5;
AnalogOn.eventValue = evs(1);

AnalogOff = sequenceElementClass;
AnalogOff.ID = 'Laser Off';
AnalogOff.holdTime = 0.5;
AnalogOff.eventValue = evs(2);

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlop.ID = sprintf('Flop %1.2f',power);
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


% ------------ Nov Laser ----------------------------------
angle = convert_cw2ccw(novAngle);
evs = 11:15;

AnalogOn = sequenceElementClass;
AnalogOn.ID = 'Laser On';
AnalogOn.holdTime = 0.5;
AnalogOn.eventValue = evs(1);

AnalogOff = sequenceElementClass;
AnalogOff.ID = 'Laser Off';
AnalogOff.holdTime = 0.5;
AnalogOff.eventValue = evs(2);

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip %1.2f',power);
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlop.ID = sprintf('Flop %1.2f',power);
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
smo = sessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(isi); % Time between sessions
smo.setInterstimulusInterval(isi); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences(seqs);
smo.startPresentation;
