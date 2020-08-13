% 

% Get the screen and make sure it is open
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

% Define parameters for stim creation and calculate the gratings, make
% shared resources and add
sf = 0.05; % spatial freqs. cy/deg
sharedResources = containers.Map;
flip = make_PR_gratings(sf,100);
sharedResources('grating_100') = Screen('MakeTexture', sio.window,flip);

holdTime = 0.15; % 150 ms % trained holdTime
nPresentations = 50; % Number of times each sequence is shown during one block
interSeqInterval = 15; % Rest time between each sequence presentation block
nBlocks = 4;

% Define the angles at each position
angles = containers.Map;
angles('A') = convert_cw2ccw(30);
angles('B') = convert_cw2ccw(90);
angles('C') = convert_cw2ccw(60);
angles('D') = convert_cw2ccw(120);

seqs = {};

% dUMMY that would turn the laser on and off but are here only to be
% consistent with prvious script
laserOn = optostimElementClass;
laserOn.ID = 'Laser Off';
laserOn.holdTime = 0.25;
ev = 1;
laserOn.eventValue = ev;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
ev = 2;
laserOff.eventValue = ev;
laserOff.setFunction('LaserOff')

% Define sequence ABCD 150ms
seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 3;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 4;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 5;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 6;

ABCD = stimulusSequenceClass('ABCD_150ms');
ABCD.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
ABCD.setNumberOfPresentations(nPresentations);


% dUMMY that would turn the laser on and off but are here only to be
% consistent with prvious script
laserOn = optostimElementClass;
laserOn.ID = 'Laser Off';
laserOn.holdTime = 0.25;
ev = 7;
laserOn.eventValue = ev;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
ev = 8;
laserOff.eventValue = ev;
laserOff.setFunction('LaserOff')

% Define sequence ABCD 150ms
seo1 = sequenceElementClass;
seo1.ID = 'D';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 9;

seo2 = sequenceElementClass;
seo2.ID = 'C';
seo2.holdTime = holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 10;

seo3 = sequenceElementClass;
seo3.ID = 'B';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 11;

seo4 = sequenceElementClass;
seo4.ID = 'A';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 12;

DCBA = stimulusSequenceClass('DCBA_150ms');
DCBA.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
DCBA.setNumberOfPresentations(nPresentations);




% Define sequence ABCD 300

% dUMMY that would turn the laser on and off but are here only to be
% consistent with prvious script
laserOn = optostimElementClass;
laserOn.ID = 'Laser Off';
laserOn.holdTime = 0.25;
ev = 13;
laserOn.eventValue = ev;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
ev = 14;
laserOff.eventValue = ev;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = 2*holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 15;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = 2*holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 16;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = 2*holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 17;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = 2*holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 18;

ABCD300 = stimulusSequenceClass('ABCD_300ms');
ABCD300.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
ABCD300.setNumberOfPresentations(nPresentations);


% Create the session manager and execute ----------------------------------
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(interSeqInterval); 
smo.setInterstimulusInterval(interSeqInterval); 
smo.setNumberOfSessions(nBlocks);
smo.addSequences({ABCD DCBA ABCD300});
smo.startPresentation;
