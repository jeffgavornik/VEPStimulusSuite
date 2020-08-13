function varargout = stimFnc_PRGrating(varargin)
% Function to display phase-reversing sinusoidal gratings with parameters
% selected via a GUI
%
% v1: Written to work with the ScrnCtrlApp
% v2: Updated from original to work with screenInterfaceClass v2.0

%#ok<*DEFNU>

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @PRGrating_OpeningFcn, ...
    'gui_OutputFcn',  @PRGrating_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
end


function PRGrating_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for PRGrating
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Initially hide the stim values
showStimValues(handles,false)

end

function varargout = PRGrating_OutputFcn(~, ~, handles)
varargout{1} = handles.output;
end


function closereq_withOverride(~, ~, handles)
% Prompt the user to make sure they are ready to quit
prompt = sprintf(...
    'Override %s lock and quit (this might cause stimulus problems)?',...
    get(handles.figure1,'Name'));
selection = questdlg(prompt,...
    ['Close ' get(handles.figure1,'Name') '...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end
if isfield(handles,'fclh')
    delete(handles.fclh);
end
delete(handles.figure1);
end

% -------------------------------------------------------------------------
% Control interfaces for the ScrnCtrlApp

function useControllingEventObject(hObject,eventObject)
% Add the event object to the guidata and redirect the close button on the
% main GUI window
handles = guidata(hObject);
handles.eventObject = eventObject;
handles.fclh = addlistener(handles.eventObject,...
    'ExitApp',@exitAppEvent_Callback);
guidata(hObject,handles);
% set(handles.figure1,'CloseRequestFcn',[]);
set(handles.figure1,'CloseRequestFcn',...
    @(hObject,eventdata)stimFnc_PRGrating('closereq_withOverride',...
    hObject,eventdata,guidata(hObject)));
end

function execute(hObject)
% dispatch stims to rendering program

% Create the stims
buildStims(hObject,true);
handles = guidata(hObject);
params = getappdata(handles.figure1,'params');
stims = getappdata(handles.figure1,'stims');
% Call routine to display stimulus
lockGUI(handles);
display_PR_stimuli_controlled(params,stims);
unlockGUI(handles);
end

function exitAppEvent_Callback(source,eventMessage) %#ok<INUSD>
% Quit the application in response to an 'ExitApp' event
hObject = stimFnc_PRGrating;
handles = guidata(hObject);
if isfield(handles,'fclh')
    delete(handles.fclh);
end
delete(handles.figure1);
end

% -------------------------------------------------------------------------
% Functions to build the stimuli based on GUI selections

function buildStims(hObject,createImages)
% Create the stims based on current GUI contents - if creatImages is false
% will only caluclate and store the event values for each stim
handles = guidata(hObject);
sfs = sort(getValues(handles.sfButton));
degs = sort(getValues(handles.degButton));
cons = sort(getValues(handles.conButton));

% Check to make sure there are not too many stimuli for the number of
% unique event words available (based on 6 bits with 0 reserved)
nStims = numel(sfs)*numel(cons)*numel(degs);
if 2*nStims > 2^6-1
    scaPrintf('stimFnc_PRGrating:Too many stims for to uniquely encode');
    error('stimFnc_PRGrating: too many unique events');
end

% Create unique stims for each combination
if createImages
    stims.images = cell(1,2*numel(sfs)*numel(cons));
    stims.degs = zeros(1,nStims);
    stims.event_vals = zeros(nStims,2);
    stims.flip_i = zeros(1,nStims);
    stims.flop_i = zeros(1,nStims);
    stims.name = 'Phase Reverse Gratings';
    stims.descriptions = cell(1,nStims);
    stims.include_gray = false;
end
stimValues = containers.Map;
stimValues('Noise') = 0;
count = 0;
imgCount = 0;
oldSF = 0; oldCon = 0;
for iSf = 1:numel(sfs)
    sf = sfs(iSf);
    for iDeg = 1:numel(degs)
        deg = degs(iDeg);
        for iCon = 1:numel(cons)
            con = cons(iCon);
            count = count + 1;
            ev_vals = 2*count-1 + [0 1]; % Event Values
            if createImages
                % note: need unique images only for SF-Contrast values 
                % figure out if a new image is needed here
                if sf == oldSF
                    newSF = false;
                else
                    oldSF = sf;
                    newSF = true;
                end
                if con == oldCon
                    newCon = false;
                else
                    oldCon = con;
                    newCon = true;
                end
                if newSF || newCon
                    imgCount = imgCount + 1;
                    imgInd = 2*imgCount - 1;
                    [flip,flop] = make_PR_gratings(sf,con);
                    stims.images{imgInd} = flip;
                    stims.images{imgInd+1} = flop;
                end
                stims.descriptions{count} = ...
                    sprintf('%1.2fcy/%c %i%c %i%%',sf,char(176),deg,...
                    char(176),con);
                stims.degs(count) = deg;
                stims.flip_i(count) = imgInd;
                stims.flop_i(count) = imgInd+1;
                stims.event_vals(count,:) = ev_vals;
            end
            % fprintf('%1.2f_%i_%i\n',sf,deg,con);
            theKey = sprintf('%1.2fcy/%c %i%c %i%%',...
                sf,char(176),deg,char(176),con);
            stimValues(theKey) = ev_vals;
        end
    end
end

% Create stim presentation parameters
if createImages
    params.flip_flop_reps = getValues(handles.ffButton);
    params.t_stim = 1/getValues(handles.freqButton);
    params.interTrialInterval = getValues(handles.isiButton);
    params.sessionsPerStim = getValues(handles.sessButton);
    params.order_type = 'random';
end

% Save app data
if createImages
    setappdata(handles.figure1,'params',params);
    setappdata(handles.figure1,'stims',stims);
end
setappdata(handles.figure1,'stimValues',stimValues);

end

function lockGUI(handles)
fields = fieldnames(handles);
for iF = 1:numel(fields)
    theHandle = handles.(fields{iF});
    if isprop(theHandle,'enable')
        set(theHandle,'enable','off');
    end
end
end

function unlockGUI(handles)
fields = fieldnames(handles);
for iF = 1:numel(fields)
    theHandle = handles.(fields{iF});
    if isprop(theHandle,'enable')
        set(theHandle,'enable','on');
    end
end
end

function vals = getValues(hObject)
userData = get(hObject,'UserData');
if isnumeric(userData)
    vals = userData;
else
    vals = cell2mat(userData.vals);
end
end

function sfButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Spatial Frequencies (cy/deg)';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
if ~isempty(resp)
    vals = regexp(resp,',','split');
    processSFValues(hObject,vals{:});
    updateStimValues(hObject);
end
end

function processSFValues(hObject,vals)
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Spatial Frequency: %1.2f cy/%s',...
        newUserData,char(176));
else
    valStr = '';
    for iV = 1:nV
        if iV == 1
            commaStr = '';
        else
            commaStr = ',';
        end
        valStr = sprintf('%s%s%s',valStr,commaStr,vals{iV});
        vals{iV} = str2double(vals{iV});
    end
    buttonStr = sprintf('SFs: %s',valStr);
    newUserData = struct;
    newUserData.vals = vals;
    newUserData.valStr = valStr;
end
set(hObject,'string',buttonStr);
set(hObject,'userdata',newUserData);
end

function degButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Stimulus Angles';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    str = regexprep(currVal.valStr,char(176),'');
    resp = inputdlg(challengeStr,'',1,{str});
end
if ~isempty(resp)
    vals = regexp(resp,',','split');
    processDegValues(hObject,vals{:});
    updateStimValues(hObject);
end
end

function processDegValues(hObject,vals)
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Angle: %i%c',newUserData,char(176));
else
    valStr = '';
    for iV = 1:nV
        if iV == 1
            commaStr = '';
        else
            commaStr = ',';
        end
        valStr = sprintf('%s%s%s%c',valStr,commaStr,vals{iV},char(176));
        vals{iV} = str2double(vals{iV});
    end
    buttonStr = sprintf('Angles: %s',valStr);
    newUserData = struct;
    newUserData.vals = vals;
    newUserData.valStr = valStr;
end
set(hObject,'string',buttonStr);
set(hObject,'userdata',newUserData);
end

function conButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Stimulus Contrasts';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
if ~isempty(resp)
    vals = regexp(resp,',','split');
    processConValues(hObject,vals{:});
    updateStimValues(hObject);
end
end

function processConValues(hObject,vals)
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Contrast: %i%%',newUserData);
else
    valStr = '';
    for iV = 1:nV
        if iV == 1
            commaStr = '';
        else
            commaStr = ',';
        end
        valStr = sprintf('%s%s%s',valStr,commaStr,vals{iV});
        vals{iV} = str2double(vals{iV});
    end
    buttonStr = sprintf('Cons: %s %%',valStr);
    newUserData = struct;
    newUserData.vals = vals;
    newUserData.valStr = valStr;
end
set(hObject,'string',buttonStr);
set(hObject,'userdata',newUserData);
end

function ffButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Flip/Flops Per Session';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
vals = regexp(resp,',','split');
vals = vals{:};
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf(' Flip/Flops Per Session: %i',newUserData);
    set(hObject,'string',buttonStr);
    set(hObject,'userdata',newUserData);
else
    errordlg('A single values is expected for Flip/Flops Per Session','Incorrect Data Format');
end
end

function sessButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Number of Sessions';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
vals = regexp(resp,',','split');
vals = vals{:};
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Sessions: %i',newUserData);
    set(hObject,'string',buttonStr);
    set(hObject,'userdata',newUserData);
else
    errordlg('A single values is expected for Sessions','Incorrect Data Format');
end
end

function isiButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Interstimulus Interval';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
vals = regexp(resp,',','split');
vals = vals{:};
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Interstimulus Interval: %i secs',newUserData);
    set(hObject,'string',buttonStr);
    set(hObject,'userdata',newUserData);
else
    errordlg('A single values is expected for Interstimulus Interval','Incorrect Data Format');
end
end

function freqButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter PR Frequency';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
vals = regexp(resp,',','split');
vals = vals{:};
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('PR Frequency: %i hz (%1.2f sec)',newUserData,1/newUserData);
    set(hObject,'string',buttonStr);
    set(hObject,'userdata',newUserData);
else
    errordlg('A single values is expected for PR Frequency','Incorrect Data Format');
end
end

function loadPredefined_Callback(src,~,handles)
switch src
    case handles.acuityMenu
        sfVals = {'0.05' '0.1' '0.2' '0.3' '0.4' '0.5' '0.6' '0.7'};
        degVals = {'45'};
        conVals = {'100'};
    case handles.contrastMenu
        sfVals = {'0.05'};
        degVals = {'45'};
        conVals = {'2' '4' '6' '8' '10' '30' '50' '100'};
end
processSFValues(handles.sfButton,sfVals);
processDegValues(handles.degButton,degVals);
processConValues(handles.conButton,conVals);
updateStimValues(src);
end

function showStims_Callback(hObject,~,handles)
checked = get(handles.showStimsMenu,'Checked');
if strcmp(checked,'on')
    showStimValues(handles,false);
else
    showStimValues(handles,true);
    updateStimValues(hObject);
end
end

function updateStimValues(src)
handles = guidata(src);
if handles.showStimValues
    buildStims(src,false);
    stimValues = getappdata(handles.figure1,'stimValues');
    stimKeys = stimValues.keys;
    nS = numel(stimKeys);
    stringCell = cell(1,nS);
    for iS = 1:nS
        theKey = stimKeys{iS};
        theVals = stimValues(theKey);
        outStr = sprintf('%i: ''%s'' = [',iS,theKey);
        for iV = 1:numel(theVals)
            outStr = sprintf('%s %i',outStr,theVals(iV));
        end
        outStr = sprintf('%s ]',outStr);
        stringCell{iS} = outStr;
        % disp(stringCell{iS})
    end
    set(handles.stimBox,'String',stringCell);
end
end

function showStimValues(handles,visible)
% Show or hide the stimulus values (visible is bool), resize the figure
% window
handles.showStimValues = visible;
if visible
    figWidth = 116.6;
    visible = 'on';
else
    figWidth = 58.5;
    visible = 'off';
end
figurePosition = get(handles.figure1,'Position');
figurePosition(3) = figWidth;
set(handles.figure1,'Position',figurePosition);
set(handles.stimPanel,'Visible',visible);
set(handles.showStimsMenu,'Checked',visible);
guidata(handles.figure1,handles);
end


