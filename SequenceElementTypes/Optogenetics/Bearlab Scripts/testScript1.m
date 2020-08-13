
%#ok<*UNRCH>

showNovel = true;

% Define parameters for stim creation and calculate the grating
sf = 0.05; % spatial freqs. cy/deg

% Define the angles at each position
angles = containers.Map;
angles('A') = convert_cw2ccw(30);
angles('B') = convert_cw2ccw(90);
angles('C') = convert_cw2ccw(60);
angles('D') = convert_cw2ccw(120);

% Get the screen and make sure it is open
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

% Create the shared resource dictionary for the sequence
sharedResources = containers.Map;

% Define sequence ABCD with 150ms
seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = 0.15;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 1;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = 0.15;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 2;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = 0.15;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 3;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = 0.15;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 4;

seoGr = sequenceElementClass;
seoGr.holdTime = 1.5;
seoGr.eventValue = 5;

ABCD = stimulusSequenceClass('ABCD');
ABCD.addSequenceElements({seo1 seo2 seo3 seo4 seoGr});

% Define sequence DCBA with 150ms
seo1 = sequenceElementClass;
seo1.ID = 'D';
seo1.holdTime = 0.15;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 6;

seo2 = sequenceElementClass;
seo2.ID = 'C';
seo2.holdTime = 0.15;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 7;

seo3 = sequenceElementClass;
seo3.ID = 'B';
seo3.holdTime = 0.15;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 8;

seo4 = sequenceElementClass;
seo4.ID = 'A';
seo4.holdTime = 0.15;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 9;

seoGr = sequenceElementClass;
seoGr.holdTime = 1.5;
seoGr.eventValue = 10;

DCBA = stimulusSequenceClass('DCBA');
DCBA.addSequenceElements({seo1 seo2 seo3 seo4 seoGr});

% Define sequence ABCD with 300ms - note: only shown to A and E
seo1 = sequenceElementClass;
seo1.ID = 'A';
seo1.holdTime = 0.3;
seo1.rotation = angles(seo1.ID);
seo1.resourceKey = 'grating_100';
seo1.resourceDict = sharedResources;
seo1.eventValue = 16;

seo2 = sequenceElementClass;
seo2.ID = 'B';
seo2.holdTime = 0.3;
seo2.rotation = angles(seo2.ID);
seo2.resourceKey = 'grating_100';
seo2.resourceDict = sharedResources;
seo2.eventValue = 17;

seo3 = sequenceElementClass;
seo3.ID = 'C';
seo3.holdTime = 0.3;
seo3.rotation = angles(seo3.ID);
seo3.resourceKey = 'grating_100';
seo3.resourceDict = sharedResources;
seo3.eventValue = 18;

seo4 = sequenceElementClass;
seo4.ID = 'D';
seo4.holdTime = 0.3;
seo4.rotation = angles(seo4.ID);
seo4.resourceKey = 'grating_100';
seo4.resourceDict = sharedResources;
seo4.eventValue = 19;

seoGr = sequenceElementClass;
seoGr.holdTime = 1.5;
seoGr.eventValue = 20;

ABCD300 = stimulusSequenceClass('ABCD300');
ABCD300.addSequenceElements({seo1 seo2 seo3 seo4 seoGr});


% Prep the textures
flip = make_PR_gratings(sf,100);
sharedResources('grating_100') = Screen('MakeTexture', sio.window,flip);

% Create the session manager and execute
smo = sessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(30); % Time between sessions
smo.setInterstimulusInterval(30); % Time between sequences within a session
if showNovel % Novel test parameters
    smo.addSequences({ABCD DCBA ABCD300});
    ABCD.setNumberOfPresentations(5);
    DCBA.setNumberOfPresentations(5);
    ABCD300.setNumberOfPresentations(5);
%     smo.setNumberOfSessions(40);
    smo.setNumberOfSessions(25);
    smo.setOrderType('InterleaveWithRepeats');
%     smo.setOrderType('Random');
else % Training Parameters
    smo.addSequences({ABCD});
    ABCD.setNumberOfPresentations(50);
    smo.setNumberOfSessions(4);
end
smo.startPresentation;
