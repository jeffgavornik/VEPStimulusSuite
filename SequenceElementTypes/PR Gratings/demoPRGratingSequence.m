
flipFlopsPerSession = 3; % Presentations per session for each condition
nSessions = 2; % Number of sessions
isi = 2; % Time between presentations

% Create PR sequence objects for each parameter set

prSeqObj1 = prGratingSequenceClass;
prSeqObj1.sequenceName = 'Familiar';
prSeqObj1.rotation = 45;
prSeqObj1.nPhaseReversals = flipFlopsPerSession;
prSeqObj1.eventValues = 1;

prSeqObj2 = prGratingSequenceClass;
prSeqObj2.sequenceName = 'Novel';
prSeqObj2.spatialFrequency = 0.3;
prSeqObj2.contrast = 20;
prSeqObj2.rotation = 90;
prSeqObj2.nPhaseReversals = flipFlopsPerSession;
prSeqObj2.eventValues = 2;

% Setup the session manager and execute
smo = sessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'random';
smo.setInterSessionInterval(isi); % Time between sessions
smo.setInterstimulusInterval(isi); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences({prSeqObj1 prSeqObj2});
smo.startPresentation;
