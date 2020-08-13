
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
seo1 = optostimElementClass;
seo1.ID = 'Pulse';
seo1.holdTime = 0.15;
seo1.resourceDict = sharedResources;
seo1.eventValue = 1;

ABCD = stimulusSequenceClass('Pulse Train');
ABCD.addSequenceElements({seo1 seo1 seo1 seo1});

% Create the session manager and execute
smo = sessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(15); % Time between sessions
smo.setInterstimulusInterval(15); % Time between sequences within a session

smo.addSequences({ABCD});
ABCD.setNumberOfPresentations(10);
smo.setNumberOfSessions(4);

smo.ttlInterface.startRecording;
WaitSecs(30);

smo.startPresentation;
