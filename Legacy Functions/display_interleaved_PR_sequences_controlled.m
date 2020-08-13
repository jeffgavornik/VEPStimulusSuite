function display_interleaved_PR_sequences_controlled(params,...
    images,sequences)

% Setup a listener to handle GUI driven UserAborts
lh = addlistener(ScrnCtrlApp('requestEventSupport'),...
    'UserAbort',@handleUserAbort);
drawnow;

nSequences = numel(sequences);
nSessions = params.sessions;
sequences_per_session = params.sequences_per_session;
interSequenceInterval = params.interSequenceInterval;

% Calculate time to execute each sequence and the total time
seqTime = zeros(1,nSequences);
for sequence = 1:nSequences
    seqTime(sequence) = sum(sequences{sequence}.flipTimes);
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
    
    % Decide order of stimulus presentations
    disp('Generating Random Stimulus Interleaving');
    cumSeqPerSess = nSequences*sequences_per_session; % cumulative number of sequences per session
    sequence_order = zeros(nSessions,cumSeqPerSess);
    sequenceValues = repmat(1:nSequences,1,sequences_per_session);
    for ii = 1:nSessions
        randomOrder = randperm(cumSeqPerSess);
        sequence_order(ii,:) = sequenceValues(randomOrder);
    end
    
    % Calculate correct angles for PTB rotation (to match
    % conventions of Italian rig)
    for iSeq = 1:nSequences
        theSequence = sequences{iSeq};
        theAngles = convert_cw2ccw(theSequence.angles);
        theSequence.angles = theAngles;
        sequences{iSeq} = theSequence;
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
        
        Priority(maxPriorityLevel);
        
        % Get stimulus order for this session
        theOrder = sequence_order(session,:);
        
        % Loop over all sequences randomly interleaved
        nextFlip = GetSecs + 0.01;
        for sequence = 1:cumSeqPerSess
            
            % Select the sequence
            iSeq = theOrder(sequence);
            nStims = sequences{iSeq}.nStims;
            stimOrder = 1:nStims;
            
            scaPrintf('%i: %s',sequence,sequences{iSeq}.name);
            
            drawnow; % flush event queue
            if user_abort
                break;
            end
            
            % Animate
            for stim = 1:nStims
                % Draw stimulus
                theIndex = stimOrder(stim);
                stimIndex = sequences{iSeq}.imageIndex(theIndex);
                if stimIndex
                    Screen('DrawTexture',window,ti(stimIndex),[],[],...
                        sequences{iSeq}.angles(theIndex));
                    plxInterface.setEventWord(sequences{iSeq}.eventValues(theIndex));
                else
                    plxInterface.setEventWord(sequences{iSeq}.eventValues(theIndex));
                end
                vbl = Screen(window,'Flip', nextFlip);
                plxInterface.strobe;
                nextFlip = vbl + sequences{iSeq}.flipTimes(theIndex) - slack;
                
            end % stim presentation loop
            
        end % sequence loop
        
        % Less worried about timing at this point so decrease
        % priority
        Priority(0);
        
        % Clear last stim
        Screen(window,'Flip',nextFlip);
        plxInterface.setEventWord(0);        
        
        % Pulse event value 0 during rest period
        if (session ~= nSessions)
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
