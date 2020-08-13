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
nBlocks = 2;

% Define the angles at each position
angles = containers.Map;
angles('A') = convert_cw2ccw(30);
angles('B') = convert_cw2ccw(90);
angles('C') = convert_cw2ccw(60);
angles('D') = convert_cw2ccw(120);
angles('E') = convert_cw2ccw(150);

seqs = {};

% Skip element B preceded by novel element
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




% Create the session manager and execute ----------------------------------
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(interSeqInterval); 
smo.setInterstimulusInterval(interSeqInterval); 
smo.setNumberOfSessions(nBlocks);
smo.addSequences({E_CD});
smo.startPresentation;