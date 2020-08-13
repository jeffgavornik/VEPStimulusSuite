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
nBlocks = 1;

% Define the angles at each position
angles = containers.Map;
angles('A') = convert_cw2ccw(30);
angles('B') = convert_cw2ccw(90);
angles('C') = convert_cw2ccw(60);
angles('D') = convert_cw2ccw(120);
angles('E') = convert_cw2ccw(150);

seqs = {};

%% Trained sequence with laser
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 1;
laserOn.setFunction('LaserOn')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 2;
laserOff.setFunction('LaserOff')

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

ABCD = stimulusSequenceClass('ABCD With Laser');
ABCD.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
ABCD.setNumberOfPresentations(nPresentations);
seqs{end+1} = ABCD;

%% Check to see if the laser is turned on but there is no visual stimulus
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 7;
laserOn.setFunction('LaserOn')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 8;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = holdTime;
seo1.eventValue = 9;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.eventValue = 10;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.eventValue = 11;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.eventValue = 12;

LaserOnly = stimulusSequenceClass('LaserOnly');
LaserOnly.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
LaserOnly.setNumberOfPresentations(nPresentations);
seqs{end+1} = LaserOnly;

%% Trained sequence with no laser
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 13;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 14;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 15;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 16;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 17;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 18;

ABCDNoLaser = stimulusSequenceClass('ABCD No Laser');
ABCDNoLaser.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
ABCDNoLaser.setNumberOfPresentations(nPresentations);
seqs{end+1} = ABCDNoLaser;

%% Reverse sequence with no laser
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 19;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 20;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 21;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 22;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 23;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 24;

DCBANoLaser = stimulusSequenceClass('DCBA No Laser');
DCBANoLaser.addSequenceElements({laserOn seo4 seo3 seo2 seo1 laserOff});
DCBANoLaser.setNumberOfPresentations(nPresentations);
seqs{end+1} = DCBANoLaser;

%% Skip element B
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 25;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 26;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 27;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.eventValue = 28;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 29;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 30;

A_CD = stimulusSequenceClass('A_CD');
A_CD.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
A_CD.setNumberOfPresentations(nPresentations);
seqs{end+1} = A_CD;

%% Reverse sequence skip 2nd element
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 31;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 32;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 33;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 34;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.eventValue = 35;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 36;

D_BA = stimulusSequenceClass('D_BA');
D_BA.addSequenceElements({laserOn seo4 seo3 seo2 seo1 laserOff});
D_BA.setNumberOfPresentations(nPresentations);
seqs{end+1} = D_BA;

%% Skip element B preceded by novel element
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 37;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 38;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'E';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 39;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.eventValue = 40;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 41;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 42;

E_CD = stimulusSequenceClass('E_CD');
E_CD.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
E_CD.setNumberOfPresentations(nPresentations);
seqs{end+1} = E_CD;

%% Skip element B preceded by novel element
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 43;
laserOn.setFunction('LaserOn')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 44;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'E';
seo1.holdTime = holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 45;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = holdTime;
seo2.eventValue = 46;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 47;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 48;

E_CDwithLaser = stimulusSequenceClass('E_CD with Laser');
E_CDwithLaser.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
E_CDwithLaser.setNumberOfPresentations(nPresentations);
seqs{end+1} = E_CDwithLaser;

%% Slow ABCD
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = 0.25;
laserOn.eventValue = 49;
laserOn.setFunction('LaserOff')

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = 1.5;
laserOff.eventValue = 50;
laserOff.setFunction('LaserOff')

seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = 2*holdTime;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 51;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = 2*holdTime;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 52;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = 2*holdTime;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 53;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = 2*holdTime;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 54;

ABCDSlow = stimulusSequenceClass('ABCD Slow');
ABCDSlow.addSequenceElements({laserOn seo1 seo2 seo3 seo4 laserOff});
ABCDSlow.setNumberOfPresentations(nPresentations);
seqs{end+1} = ABCDSlow;

%% Run it
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(interSeqInterval); 
smo.setInterstimulusInterval(interSeqInterval); 
smo.setNumberOfSessions(nBlocks);
smo.addSequences(seqs);
smo.setOrderType('Specified',[1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9]);
smo.startPresentation;