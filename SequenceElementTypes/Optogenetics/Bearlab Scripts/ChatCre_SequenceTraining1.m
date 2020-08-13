ConfigureDigitalOptoStimControl(false);

% Get the screen and make sure it is open
sio = screenInterfaceClass.returnInterface;
sio.openScreen;

% Define parameters for stim creation and calculate the gratings, make
% shared resources and add
sf = 0.05; % spatial freqs. cy/deg
angle = convert_cw2ccw(45);
sharedResources = containers.Map;
[flip,flop] = make_PR_gratings(sf,100);
sharedResources('flip') = Screen('MakeTexture', sio.window,flip);
%sharedResources('flop') = Screen('MakeTexture', sio.window,flop);

nPresPerSession = 50;
nSessions = 4;

% Define the angles at each position
A__ = convert_cw2ccw(30);
B__ = convert_cw2ccw(90);
C__ = convert_cw2ccw(60);
D__ = convert_cw2ccw(120);

holdTime = 0.20;
laserHoldTime = 0.5;
offHoldTime = 0.1;

% Laser on, A, B, C, D, Laser off.  No event for gray
ABCDEvents = [ 1 2 3 4 5 6 7]; 

% ------------------------------------------------------------------------
% Make a sequence were the laser is on during visual stimulus presentation

% Make the laser on and off elements
% On 0.5 sec before visual stimulus, off half second after last element, 5
% seconds rest
laserOn = optostimElementClass;
laserOn.ID = 'Laser On';
laserOn.holdTime = laserHoldTime;
laserOn.resourceDict = sharedResources;
laserOn.eventValue = ABCDEvents(1);
laserOn.setFunction('LaserOn')

seoA = sequenceElementClass;
seoA.ID = 'A';
seoA.holdTime = holdTime;
seoA.rotation = A__;
seoA.resourceKey = 'flip';
seoA.resourceDict = sharedResources;
seoA.eventValue = ABCDEvents(2);

seoB = sequenceElementClass;
seoB.ID = 'B';
seoB.holdTime = holdTime;
seoB.rotation = B__;
seoB.resourceKey = 'flip';
seoB.resourceDict = sharedResources;
seoB.eventValue = ABCDEvents(3);

seoC = sequenceElementClass;
seoC.ID = 'C';
seoC.holdTime = holdTime;
seoC.rotation = C__;
seoC.resourceKey = 'flip';
seoC.resourceDict = sharedResources;
seoC.eventValue = ABCDEvents(4);

seoD = sequenceElementClass;
seoD.ID = 'D';
seoD.holdTime = holdTime;
seoD.rotation = D__;
seoD.resourceKey = 'flip';
seoD.resourceDict = sharedResources;
seoD.eventValue = ABCDEvents(5);

spacer = sequenceElementClass;
spacer.ID = 'Spacer';
spacer.holdTime = laserHoldTime;
spacer.eventValue = ABCDEvents(6);

laserOff = optostimElementClass;
laserOff.ID = 'Laser Off';
laserOff.holdTime = offHoldTime;
laserOff.resourceDict = sharedResources;
laserOff.eventValue =  ABCDEvents(7);
laserOff.setFunction('LaserOff')

seoGray = sequenceElementClass;
seoGray.holdTime = 1.5 - laserHoldTime - offHoldTime; % Laser off time as well

% Create the sequence
abcdSeq = stimulusSequenceClass('OptoSeq');
abcdSeq.addSequenceElements({...
    laserOn, seoA, seoB, seoC, seoD, spacer, laserOff, seoGray});
abcdSeq.setNumberOfPresentations(nPresPerSession);

% Create the session manager and execute
smo = optoSessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'random';
smo.setInterSessionInterval(15); % Time between sessions
smo.setInterstimulusInterval(15); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences({abcdSeq});
smo.startPresentation;
