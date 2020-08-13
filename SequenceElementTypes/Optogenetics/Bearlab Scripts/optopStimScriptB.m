ConfigureAnalogOptoStimControl();

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
sharedResources('flop') = Screen('MakeTexture', sio.window,flop);

nPresPerSession = 10;
nSessions = 2;

powerLevels = linspace(1.5,3,5);
seqs = cell(1,length(powerLevels));
ev = 0;

for iP = 1:length(powerLevels)
    powerLevel = powerLevels(iP);
    
    % Make the laser on and off elements
    % On 0.5 sec before visual stimulus, off half second after last element, 5
    % seconds rest
    laserOn = optostimElementClass;
    laserOn.ID = 'Laser On';
    laserOn.holdTime = 0.5;
    laserOn.resourceDict = sharedResources;
    ev = ev + 1;
    laserOn.eventValue = ev;
    laserOn.setFunction('AnalogOn',powerLevel/5)
    
    laserOff = optostimElementClass;
    laserOff.ID = 'Laser Off';
    laserOff.holdTime = 10;
    laserOff.resourceDict = sharedResources;
    ev = ev + 1;
    laserOff.eventValue = ev;
    laserOff.setFunction('AnalogOff')
    
    % Make the visual only elements - uniquely number events so that it is easy
    % to see if the inhibition loses efficacy over time
    seoFlip = sequenceElementClass;
    seoFlip.ID = sprintf('Flip %1.2f',powerLevel);
    seoFlip.holdTime = 0.5;
    seoFlip.rotation = angle;
    seoFlip.resourceKey = 'flip';
    seoFlip.resourceDict = sharedResources;
    ev = ev + 1;
    seoFlip.eventValue = ev;
    
    seoFlop = sequenceElementClass;
    seoFlip.ID = sprintf('Flop %1.2f',powerLevel);
    seoFlop.holdTime = 0.5;
    seoFlop.rotation = angle;
    seoFlop.resourceKey = 'flop';
    seoFlop.resourceDict = sharedResources;
    ev = ev + 1;
    seoFlop.eventValue = ev;
    
    spacer = sequenceElementClass;
    spacer.ID = 'Spacer';
    spacer.holdTime = 0.5;
    ev = ev + 1;
    spacer.eventValue = ev;
    
    % Create the sequence
    optoSeq = stimulusSequenceClass(sprintf('OptoSeq PL=%f',powerLevel));
    optoSeq.addSequenceElements({...
        laserOn ...
        seoFlip seoFlop ...
        seoFlip seoFlop ...
        seoFlip seoFlop ...
        seoFlip seoFlop ...
        seoFlip seoFlop ...
        spacer ...
        laserOff ...
        });
    optoSeq.setNumberOfPresentations(nPresPerSession);
    seqs{iP} = optoSeq;
    
end


% Create the session manager and execute
smo = sessionManagerClass;
smo.provideSCASupport();
smo.orderType = 'random';
smo.setInterSessionInterval(10); % Time between sessions
smo.setInterstimulusInterval(10); % Time between sequences within a session
smo.setNumberOfSessions(nSessions);
smo.addSequences(seqs);
smo.startPresentation;
