function display_PR_sequences_controlled(params,images,sequences)

% 27 April 2012 - Fixed interstim gray criteria

% Get parameters from passed params and stimulus structures
order_type = params.order_type; % sequential or random

% If specified sequence order_type, nSequences is equal to the number of
% elements in the specified order
switch lower(order_type)
    case 'specified'
        if isfield(params,'sequence_order')
            sequence_order = params.sequence_order;
            nSequences = numel(sequence_order);
        else
            error('display_PR_stimuli: no seq order specified')
        end
    case 'randominterleaved'
        display_interleaved_PR_sequences_controlled(params,...
            images,sequences);
        return;
    otherwise
        nSequences = numel(sequences);
end
nSessions = params.sessions;
sequences_per_session = params.sequences_per_session;
interSequenceInterval = params.interSequenceInterval;

useMask = false;

% Setup a listener to handle GUI driven UserAborts
lh = addlistener(ScrnCtrlApp('requestEventSupport'),'UserAbort',@handleUserAbort);
drawnow;

% Calculate time to execute each sequence and the total time
seqTime = zeros(1,nSequences);
for sequence = 1:nSequences
    if exist('sequence_order','var')
        seqTime(sequence) = sum(sequences{sequence_order(sequence)}.flipTimes);
    else
        seqTime(sequence) = sum(sequences{sequence}.flipTimes);
    end
end
totalTime = sequences_per_session * nSessions * sum(seqTime) + ...
    + (nSessions*nSequences-1)*interSequenceInterval;
time_str = sprintf('Required time for %i sequences = %s\n',...
    nSequences,secs2Str(totalTime));

% Setup IO hardware interface to send data to Plexon
plxInterface = plxHWInterface;

try
    
    % Query ScrnCtrlApp for an open window
    window = ScrnCtrlApp('returnScreenWindow');
    slack = Screen(window,'GetFlipInterval')/2;
    ScrnCtrlApp('requestSynchronousScreenControl')
    
    % Make textures from image matrici
    ti = zeros(1,numel(images));
    for ii = 1:length(images)
        ti(ii)=Screen('MakeTexture', window,images{ii});
    end
    
    if useMask
        % Make a masking texture
        ScrnCtrlApp('enableAlphaBlending')
        mp = ScrnCtrlApp('returnMonitorProfile');
        [x,y] = meshgrid(-mp.cols/2:mp.cols/2-1,-mp.rows/2:mp.rows/2-1);
        maskImage = ones(mp.rows,mp.cols,2) * mp.gray;
        r = mp.rows/2;
        maskImage(:,:,2) = mp.white-exp(-((x/r).^3)-((y/r).^3))*mp.white;
        mt = Screen('MakeTexture',window,uint8(maskImage));
    end
    
    % Decide order of stimulus presentations
    switch lower(order_type)
        case 'random'
            disp('Generating Random Stimulus order');
            sequence_order = zeros(nSessions,nSequences);
            for ii = 1:nSessions
                sequence_order(ii,:) = randperm(nSequences);
            end
            % case 'sequential'
            % disp('Using Sequential Stimulus order');
            % stim_order = repmat([1:n_stims],nSessionsPerStim,1);
        case 'specified'
            disp('Using User Specified Stimulus order');
            sequence_order = repmat(sequence_order,nSessions,1);
        case 'grouped'
            disp('Generating Random Grouped Stimulus order');
            sequence_order = zeros(1,nSessions*nSequences);
            grpOrder = randperm(nSequences);
            % grpOrder = [1 randperm(nSequences-1)+1]
            for ii = 1:nSequences
                rangeStart = (ii-1)*nSessions+1;
                range = rangeStart:rangeStart+nSessions-1;
                sequence_order(range) = grpOrder(ii);
            end
            nSequences = numel(sequence_order);
            nSessions = 1;
        case 'groupedsequential'
            sequence_order = zeros(1,nSessions*nSequences);
            grpOrder = [1 nSequences];
            for ii = 1:nSequences
                rangeStart = (ii-1)*nSessions+1;
                range = rangeStart:rangeStart+nSessions-1;
                sequence_order(range) = grpOrder(ii);
            end
            nSequences = numel(sequence_order);
            nSessions = 1;
        otherwise
            error('display_flipFlop_stimuli: unknown order_type');
    end
    
    scaPrintf('%s',time_str);
    
    % Tell Plexon to start recording
    plxInterface.startRecording;
    
    % Attempt to minimize system interuptions with timing
    if strcmp(computer,'GLNX86')
        maxPriorityLevel = 99;
    else
        maxPriorityLevel = MaxPriority(window);
    end
    
    
    % Keep track of elapsed time
    scaPrintf('Starting stimulus presentation sequence....');
    t1 = tic;
    user_abort = false; % flag to return to sequence start point
    for session = 1:nSessions
        if user_abort
            break
        end
        % Display status
        scaPrintf('Session %i of %i',session,nSessions);
        
        % Get stimulus order for this session
        theOrder = sequence_order(session,:);
        
        % Loop over all sequences in the specified order
        for sequence = 1:nSequences
            Priority(maxPriorityLevel);
            
            iSeq = theOrder(sequence);
            theSequence = sequences{iSeq};
            tmpStr = sprintf('Showing sequence: %s',theSequence.name);
            nStims = theSequence.nStims;
            baseStimOrder = 1:nStims;
            stimOrder = baseStimOrder;
            
            % Select for random sequence order each presentation
            if isfield(theSequence,'randomizeStimsWithinSequence')
                tmpStr = sprintf('%s (Random stim order within sequence)',tmpStr);
                randomStimOrder = true;
                randIndici = theSequence.randomizeStimsWithinSequence;
                nRandIndici = numel(randIndici);
            else
                randomStimOrder = false;
            end
            
            % Select for random sequence timing within each presentation
            if isfield(theSequence,'randomizeStimTimesWithinSequence')
                if randomStimOrder
                    error('display_PR_sequences_controlled: can not have both random times and order');
                end
                tmpStr = sprintf('%s (Random stim times within sequence)',tmpStr);
                randomStimTimes = true;
                randIndici = theSequence.randomizeStimTimesWithinSequence;
                nRandIndici = numel(randIndici);
                percentWindow = theSequence.timeRandomizationWindowPercents;
                constantEnvelope = theSequence.constantTimeEnvelope;
            else
                randomStimTimes = false;
            end
            scaPrintf(tmpStr);
            
            % Calculate correct angles for PTB rotation (to match
            % conventions of Italian rig)
            theAngles = convert_cw2ccw(theSequence.angles);
            
            nextFlip = GetSecs + 0.01;
            
            for presentationNumber = 1:sequences_per_session
                drawnow; % flush event queue
                if user_abort
                    break;
                end
                
                if randomStimOrder
                    % randomize order within the sequence
                    randOrder = randperm(nRandIndici);
                    stimOrder(randIndici) = ...
                        baseStimOrder(randIndici(randOrder));
                end
                
                flipTimes = theSequence.flipTimes;
                if randomStimTimes
                    flipTimes(randIndici) = ...
                        randomSequenceTimes(flipTimes(randIndici),...
                        percentWindow,constantEnvelope);
                end
                
                for stim = 1:nStims
                    % Draw stimulus
                    theIndex = stimOrder(stim);
                    stimIndex = theSequence.imageIndex(theIndex);
                    if stimIndex
                        Screen('DrawTexture',window,ti(stimIndex),[],[],theAngles(theIndex));
                        plxInterface.setEventWord(theSequence.eventValues(theIndex));
                    else
                        plxInterface.setEventWord(theSequence.eventValues(theIndex));
                    end
                    if useMask
                        Screen('DrawTexture',window,mt);
                    end
                    vbl = Screen(window,'Flip', nextFlip);
                    plxInterface.strobe;
                    nextFlip = vbl + flipTimes(theIndex) - slack;
                    
                end % stim presentation loop
            end % sequence presentation loop
            
            % Clear last stim
            Screen(window,'Flip',nextFlip);
            plxInterface.setEventWord(0);
            
            % Less worried about timing at this point so decrease
            % priority
            Priority(0);
            
            % Exit loop on user abort
            drawnow; % flush event queue
            if user_abort
                break;
            end
            
            % Pulse event value 0 during rest period
            lastSession = session == nSessions;
            lastSequence = sequence == nSequences;
            if ~(lastSession && lastSequence)
                WaitSecs(0.5); % avoid recording off-response
                gray_pulses = round(interSequenceInterval/0.5)-1;
                for pulse = 1:gray_pulses
                    drawnow; % flush event queue
                    if user_abort
                        break;
                    end
                    start = GetSecs;
                    plxInterface.strobe;
                    stop = GetSecs;
                    WaitSecs(0.5 -(stop-start));
                end
            end
            
        end % sequence loop
    end % session loop
    
    % Tell Plexon to pause recording
    plxInterface.stopRecording;
    scaPrintf('Actual time used for session: %s',secs2Str(toc(t1)));
   
catch ME
    % Exit gracefully if something goes wrong
    beep;
    fprintf('Error in try block\nReport\n%s',getReport(ME))
end

% Restore and quit
ScrnCtrlApp('releaseSynchronousScreenControl');
plxInterface.closeInterface;
delete(lh);

    function handleUserAbort(src,data) %#ok<INUSD>
        scaPrintf('User Abort');
        user_abort = true;
        drawnow
    end

end
