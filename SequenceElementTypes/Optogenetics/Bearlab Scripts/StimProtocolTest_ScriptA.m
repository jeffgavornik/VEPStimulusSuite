% Test and compare various stimulus-laser pairing protocols
%
% Bracket each individual phase reversal by a laser pulse

%#ok<*SAGROW,*NASGU>

% -------------------------------------------------------------------------
% ---------------- Set Stimulus Parameters --------------------------------

stimAngle = 45;

flipFlopsPerPres = 30; % Contiguous flip-flop pairs per presentation
nPresPerSession = 1; % Presentations per session for each condition
nSessions = 5; % Number of sessions
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

ConfigureDigitalOptoStimControl(false);

seqs = {};

% -------------------------------------------------------------------------
% Bracket each individual phase reversal by a laser pulse
theAngle = convert_cw2ccw(stimAngle);
evs = 1:4;
bracketWidth = 0.25;

DigitalOn = optostimElementClass;
DigitalOn.ID = 'Laser On';
DigitalOn.holdTime = bracketWidth/2;
DigitalOn.eventValue = evs(1);
DigitalOn.setFunction('DigitalOn')

DigitalOff = optostimElementClass;
DigitalOff.ID = 'Laser Off';
DigitalOff.holdTime = bracketWidth/2;
DigitalOff.eventValue = evs(2);
DigitalOff.setFunction('DigitalOff')

seoFlip = sequenceElementClass;
seoFlip.ID = sprintf('Flip');
seoFlip.holdTime = 0.5 - bracketWidth/2;
seoFlip.rotation = theAngle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);

seoFlop = sequenceElementClass;
seoFlip.ID = sprintf('Flop');
seoFlop.holdTime = 0.5 - bracketWidth/2;
seoFlop.rotation = theAngle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
seoFlop.eventValue = evs(4);

optoSeq = stimulusSequenceClass(sprintf('Angle = %i, Stim Bracket Width = %1.3f',...
    convert_cw2ccw(theAngle),bracketWidth));
seqElmnts = { };
for iS = 1:flipFlopsPerPres
    seqElmnts(end+[1 2 3 4]) = {DigitalOn,seoFlip,seoFlop,DigitalOff}; 
end
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
