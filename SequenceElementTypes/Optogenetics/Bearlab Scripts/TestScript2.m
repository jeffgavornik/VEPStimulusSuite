% Look for SRP modulated vidget in PV-Cre mice expressing ChR in V1
%
% Show fam and nov angles with and without laser turned on
% Assumes digital 

%#ok<*SAGROW,*NASGU>

% -------------------------------------------------------------------------
% ---------------- Set Stimulus Parameters --------------------------------

famAngle = 45;

DigitalOffHoldTime = 5; % Hold time after the laser turns off
flipFlopsPerPres = 30; % Contiguous flip-flop pairs per presentation
nPresPerSession = 1; % Presentations per session for each condition
nSessions = 5; % Number of sessions
isi = 30; % Time between presentations

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Get the screen and make sure it is open
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

osi = optoStimHWInterface;
osi.setConfigType('Digital');

% Define parameters for stim creation and calculate the gratings, make
% shared resources and add
sf = 0.05; % spatial freqs. cy/deg
sharedResources = containers.Map;
[flip,flop] = make_PR_gratings(sf,100);
sharedResources('flip') = Screen('MakeTexture', sio.window,flip);
sharedResources('flop') = Screen('MakeTexture', sio.window,flop);

% Set isi to be true gray period
isi = isi-DigitalOffHoldTime;

seqs = {};

% ------------ Fam With Laser ----------------------------------
angle = convert_cw2ccw(famAngle);
evs = 1:5;

% DigitalOn = optostimElementClass;
% DigitalOn.ID = 'Laser On';
% DigitalOn.holdTime = 0.5;
% DigitalOn.eventValue = evs(1);
% DigitalOn.setFunction('LaserOn')
% 
% DigitalOff = optostimElementClass;
% DigitalOff.ID = 'Laser Off';
% DigitalOff.holdTime = DigitalOffHoldTime;
% DigitalOff.eventValue = evs(2);
% DigitalOff.setFunction('LaserOff')

seoFlip = optostimElementClass;
seoFlip.ID = sprintf('Flip');
seoFlip.holdTime = 0.5;
seoFlip.rotation = angle;
seoFlip.resourceKey = 'flip';
seoFlip.resourceDict = sharedResources;
seoFlip.eventValue = evs(3);
seoFlip.setFunction('LaserOn');

seoFlop = optostimElementClass;
seoFlip.ID = sprintf('Flop');
seoFlop.holdTime = 0.5;
seoFlop.rotation = angle;
seoFlop.resourceKey = 'flop';
seoFlop.resourceDict = sharedResources;
seoFlop.eventValue = evs(4);
seoFlop.setFunction('LaserOff');

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = 0.5;
spacer.eventValue = evs(5);

optoSeq = stimulusSequenceClass(sprintf('OptoSeq %i PL=%1.2f',...
    convert_cw2ccw(angle),1));
seqElmnts = {}; %{ DigitalOn };
for iS = 1:flipFlopsPerPres
    seqElmnts(end+[1 2]) = {seoFlip,seoFlop}; 
end
%seqElmnts(end+[1 2]) = { spacer DigitalOff };
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
