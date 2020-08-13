
%#ok<*SAGROW,*NASGU>

% sio = screenInterfaceClass.returnInterface;
% sio.openScreen;

% -------------------------------------------------------------------------
% ---------------- Set Stimulus Parameters --------------------------------

nSessions = 1; % Number of sessions
isi = 5; % Time between presentations

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

seqs = {};

driftSeq = driftGratingSequenceClass('Drift');
seqs{end+1} = driftSeq;


% Create the session manager and execute ----------------------------------
smo = sessionManagerClass;
smo.provideSCASupport();
smo.setInterSessionInterval(isi); % Time between sessions
smo.setInterstimulusInterval(isi); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences(seqs);
smo.startPresentation;

% sio.closeScreen;