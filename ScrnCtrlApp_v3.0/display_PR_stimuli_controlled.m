function display_PR_stimuli_controlled(params,stims)
% Function to take flip and flop image matrici and present using the
% psychtoolbox
%
% Takes parameter and stimulus structures
%
% 3/8/10 - v0.1     Created from the ashes of accidental directory deletion
% 6/11/10 - v0.2    Ported to work with new stimulus generating code, let
%                   PTB perform rotation
% 1/28/11 - v0.3    Updated to work with calibration suite data
% 8/27/15 - v2      Modified to work with screenInterfaceClass v2


% Setup a listener to handle GUI driven UserAborts
lh = addlistener(ScrnCtrlApp('requestEventSupport'),'UserAbort',...
    @handleUserAbort_Callback);
drawnow;

% Get the screen, TTL, and logging interfaces
sio = screenInterfaceClass.returnInterface;
ttlInterface = ttlInterfaceClass.getTTLInterface;
expLog = experimentalRecordsClass;

% Get parameters from passed params and stimulus structures
flip_flop_reps = params.flip_flop_reps; % per stimuli session
t_stim = params.t_stim; % duration, in seconds, of each stimulus
interTrialInterval = params.interTrialInterval; % rest breaks for the mouse, in seconds
sessionsPerStim = params.sessionsPerStim; % number of times to present each stimulu
order_type = params.order_type; % sequential or random
stim_name = stims.name; % descriptive string
n_stims = length(stims.degs) + stims.include_gray; % number of unique stimuli

% Write to the log file
if expLog.isReadyToLog
    fprintf(2,'%s: log stimulus details here\n',mfilename);
else
    expLog.showConfigWarning(sprintf('%s: experimentalRecordsClass not ready.  No logging will occur.\n',mfilename));
end

WaitSecs(0.1); % Let all the GUIs settle...
try
    
    % Get the rendering window and request control of the ScrnCtrlApp
    window = sio.getWindow;
    if ~ScrnCtrlApp('requestSynchronousScreenControl')
        error('requestSynchronousScreenControl denied');
    end
        
    % Correct presentation time based on window timing
    t_stim = t_stim - sio.slack;
    
    % Make textures from image matrici
    for ii = 1:length(stims.images)
        ti(ii)=Screen('MakeTexture', window,stims.images{ii}); %#ok<AGROW>
    end
    
    % Decide order of stimulus presentations
    switch lower(order_type)
        case 'random'
            scaPrintf('Generating Random Stimulus order\n');
            stim_order = zeros(sessionsPerStim,n_stims);
            for ii = 1:sessionsPerStim
                if stims.include_gray
                    stim_order(ii,:) = randperm(n_stims)-1; % 0 is gray
                else
                    stim_order(ii,:) = randperm(n_stims);
                end
            end
        case 'sequential'
            scaPrintf('Using Sequential Stimulus order\n');
            stim_order = repmat(1:n_stims,sessionsPerStim,1);
        case 'specified'
            scaPrintf('Using User Specified Stimulus order\n');
            if isfield(params,'stim_order')
                stim_order = params.stim_order;
            else
                error('display_PR_stimuli: no stim order specified')
            end
            stim_order = repmat(stim_order,sessionsPerStim,1);
        otherwise
            error('display_flipFlop_stimuli: unknown order_type');
    end
    
    % Figure out about how long it will take to show all the stimuli and 
    % tell the user
    if exist('stim_order','var')
        [~,n_actual] = size(stim_order);
    else
        n_actual = n_stims;
    end
    req_t = n_actual*sessionsPerStim*(2*t_stim*flip_flop_reps + ...
        interTrialInterval) - interTrialInterval;
    scaPrintf('%s\nApproximate required time = %s\n',...
        stim_name,secs2Str(req_t));
        
    % Tell the recording system to start recording
    ttlInterface.startRecording;
        
    scaPrintf('Starting stimulus presentation sequence....\n');
    % LOG
    
    t1 = tic;
    user_abort = false; % flag to return to sequence start point
    for session = 1:sessionsPerStim
        drawnow; % flush event queue
        if user_abort
            break
        end
        % Display status
        scaPrintf('Session %i of %i\n',session,sessionsPerStim);
        used_t = toc(t1);
        rem_t = req_t - used_t;
        scaPrintf('Elapsed time = %s, approximate time remaining = %s\n',...
            secs2Str(used_t),secs2Str(rem_t));
        % Get stimulus order for this session
        order = stim_order(session,:);
        % Loop over all stimuli with high priority
        sio.setHighPriority();
        for stim = 1:n_actual
            stim_i = order(stim);
            if stim_i == 0
                gray_session = true;
            else
                gray_session = false;
                angle = convert_cw2ccw(stims.degs(stim_i));
                flip_index = stims.flip_i(stim_i);
                flop_index = stims.flop_i(stim_i);
                flip_value = stims.event_vals(stim_i,1);
                flop_value = stims.event_vals(stim_i,2);
            end
            scaPrintf('%s [%i %i]\n',stims.descriptions{stim_i},flip_value,flop_value);
            % LOG
            
            start = GetSecs; % starting time for first flip-stim reference
            next_time = start + 0.01;
            for ff_num = 1:flip_flop_reps
                drawnow; % flush event queue
                if user_abort
                    break
                end
                % Draw flip stim
                if ~gray_session
                    if flip_index > 0
                        Screen('DrawTexture',window,ti(flip_index),[],[],angle);
                    end
                    ttlInterface.setEventWord(flip_value);
                    
                else
                    ttlInterface.setEventWord(0);
                end
                flip_on = sio.flipScreen(next_time);
                ttlInterface.strobe;
                next_time = flip_on + t_stim;
                
                drawnow; % flush event queue
                if user_abort
                    break
                end
                % Draw flop stim
                if ~gray_session
                    if flop_index > 0
                        Screen('DrawTexture',window,ti(flop_index),[],[],angle);
                    end
                    ttlInterface.setEventWord(flop_value);
                else
                    ttlInterface.setEventWord(0);
                end
                flop_on = sio.flipScreen(next_time);
                ttlInterface.strobe;
                next_time = flop_on + t_stim;
            end
            
            % Show gray inbetween stims
            sio.flipScreen(flop_on + t_stim);
            ttlInterface.setEventWord(0);
            
            % Exit loop on user abort
            if user_abort
                break;
            end
            
            % Less worried about timing now so lower priority, let the
            % system do anything it needs to now
            sio.setLowPriority();
            
            % Show interstimulus gray
            if (session ~= sessionsPerStim) || (stim ~= length(order))
                WaitSecs(t_stim); % avoid recording off-response
                % Pulse white screen noise during rest period
                gray_pulses = round(interTrialInterval/t_stim)-2;
                for pulse = 1:gray_pulses
                    drawnow; % flush event queue
                    if user_abort
                        break;
                    end
                    start = GetSecs;
                    ttlInterface.strobe;
                    stop = GetSecs;
                    WaitSecs(t_stim - (stop-start));
                end
            end
        end % stim loop
    end % session loop
    
    % Tell the recording system to stop recording
    ttlInterface.stopRecording;
    scaPrintf('Actual time used for session: %s\n',secs2Str(toc(t1)));
    
catch ME
    % Exit gracefully if something goes wrong
    handleError(ME,true,'display_PR_stimuli_controlled try block error');
end

% Restore and quit
sio.setLowPriority();
if exist('ti','var')
    Screen('close',ti);
end
ScrnCtrlApp('releaseSynchronousScreenControl');
delete(lh);

    function handleUserAbort_Callback(src,data) %#ok<INUSD>
        scaPrintf('userAbort\n');
        user_abort = true;
        drawnow
    end


end
