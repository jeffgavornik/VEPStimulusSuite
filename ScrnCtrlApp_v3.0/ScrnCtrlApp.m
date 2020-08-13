function varargout = ScrnCtrlApp(varargin)
% Version 2.1 uses screenInterfaceClass to support sequenceDispatchEngine
% control

%#ok<*DEFNU>
%#ok<*NASGU>
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ScrnCtrlApp_OpeningFcn, ...
    'gui_OutputFcn',  @ScrnCtrlApp_OutputFcn, ...
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
% End initialization code - DO NOT EDIT
end

function ScrnCtrlApp_OpeningFcn(hObject,~,handles, varargin)

% Choose default command line output for ScrnCtrlApp
handles.output = hObject;

% Look for screenInterface to see if this is the first time the app has
% been evoked - if so, create new appdata and handle fields
if ~isappdata(hObject,'ScreenInterface')
    
    % Get the screenInterfaceObject - this object sits between the user and
    % Psychtoolbox and is responsible for managing monitor calibration,
    % alpha blending, etc. Listen for screenInterface state change event
    % notification
    sio = screenInterfaceClass.returnInterface;
    setappdata(hObject,'ScreenInterface',sio);
    handles.evntListeners = addlistener(sio,...
        'ScreenClosing',@(hObj,evntData)updateGUI());
    handles.evntListeners(end+1) = addlistener(sio,...
        'ScreenOpening',@(hObj,evntData)updateGUI());
    handles.evntListeners(end+1) = addlistener(sio,...
        'AlphaBlendingChanged',@(hObj,evntData)updateGUI());
    
    % Create a queue to hold application messages
    setappdata(hObject,'appMessages',stringQueueClass);
    
    % Create a lock to allow applications to take control of the screen
    handles.lock = false;
    
    % Indicate that no stimulus function is loaded
    setappdata(hObject,'fncLoaded',false);
    
    % Indicate that there are no current warnings
    setappdata(hObject,'activeWarning',false);
    
    % Disable the menu item that allows loading of stimulus functions - no
    % one uses them and it is not a well defined methodology
    set(handles.loadStimFncMenu,'visible','off');
    
    % Redirect the delete function for the app window to call a function that
    % will shutdown psychtoolbox and remove the app handle from userdata
    set(handles.figure1,'CloseRequestFcn',...
        @(hObject,eventdata)ScrnCtrlApp('closereq_withVerify',...
        hObject,eventdata,guidata(hObject)));
    
    % Create a variable that can checked for user abort requests
    handles.userAbort = false;
    
    % Create an object to setup event handling
    handles.scaEventObject = scaEventClass(hObject);
    
    % Create a listener for FunctionCompleted notification
    handles.fclh = addlistener(handles.scaEventObject,...
        'FunctionCompleted',@completionEvent_Callback);
    
    % Set the delay to script execution
    setappdata(hObject,'delayToExecute',0);
    
    % Allow the user to override the lock if a script dies in a bad way
    set(handles.lockBox,...
        'ButtonDownFcn',@(hObj,evnt)manualUnlock(hObj));
    
    % Setup the TTL interface monitor and override
    handles.ttlInterface = ttlInterfaceClass.getTTLInterface;
    userData.isValid = handles.ttlInterface.validateInterface;
    userData.override = handles.ttlInterface.warningsAreSuppressed;
    set(handles.ttlOverrideButton,...
        'ButtonDownFcn',@(hObj,evnt)toggleTTLOverride(hObj),...
        'UserData',userData);
    
    % Setup for experiment logging
    handles.loggingInterface = experimentalRecordsClass;
    handles.loggingInterface.guiPopupMenu = handles.userSelectionMenu;
    handles.evntListeners(end+1) = addlistener(handles.loggingInterface,...
        'UserSelectionChanged',@(hObj,evntData)handleUserSelectionChange(hObj));
    set([handles.animalIDTxt,handles.sessionNameTxt,handles.experimentDescriptionTxt],...
        'Callback',@(hObj,evnt)handleUserExperimentDataChange(hObj));
    set(handles.logExpNotesButton,...
        'Callback',@(hObj,evnt)logUserNotes(hObj));
    set(handles.viewLogButton,...
        'Callback',@(hObj,evnt)viewExpLog(hObj));
    set(handles.experimentDescriptionTxt,'UserData','clean');
    set(handles.logOverrideButton,...
        'ButtonDownFcn',@(hObj,evnt)toggleLogOverride(hObj),...
        'UserData',handles.loggingInterface.warningsAreSuppressed);
    set(handles.metadataBox,'Callback',...
        @(hObj,evnt)toggleMetadataControl(hObj,handles));
    
    % Setup the email interface used to send stimulus completetion
    % notifications
    handles.emailInterface = mailInterfaceClass;
    setappdata(handles.figure1,'notifyOnCompletion',false);
    set(handles.emailAddressField,'Callback',...
        @(hObject,eventdata)handleNotificationSelectionChange(hObject));
    
    % If the app has been opened in standalone mode, find and hide the
    % desktop window
    handles.standalone = false;
    if numel(varargin) > 0 && strcmpi('standalone',varargin{1})
        try
            handles.dtw = findDesktopWindow;
            hideDesktopWindow(handles);
            launchScreenMenu_Callback([],[],handles);
            handles.standalone = true;
        catch ME
            handleWarning(ME,true,'ScrnCtrlApp.standalone mode failure',...
                2,true)
        end
    else
        set(handles.dtwVisibilityMenu,'visible','off');
    end
    
end
    
% Update handles structure
guidata(hObject,handles);
updateGUI(handles);

end

function varargout = ScrnCtrlApp_OutputFcn(~,~,handles)
varargout{1} = handles.output;
end

function updateGUI(handles)

if nargin == 0
    handles = guidata(ScrnCtrlApp('returnFigure'));
end
try
    handles = guidata(handles.figure1); % Make sure this is fresh
catch ME
    handles = guidata(ScrnCtrlApp('returnFigure'));
    handleWarning(ME,false,'ScrnCtrlApp:Figure 1 bad warning',2);
end

% Set the screen open/closed indicator
sio = getappdata(handles.figure1,'ScreenInterface');
if sio.verifyWindow % Window is open
    % Show green if the screenInterface reports a calibrated monitor.
    % Otherwise, show yellow
    if sio.openScreen % true if calibrated monitor
        set(handles.screenToggleButton,'Backgroundcolor',[0 1 0]);
        set(handles.scrnStateString,'String','Screen Open');
    else
        set(handles.screenToggleButton,'Backgroundcolor',[1 1 0]);
        set(handles.scrnStateString,'String','Uncalibrated');
    end
else
    % Window is closed, show a red button
    set(handles.screenToggleButton,'Backgroundcolor',[1 0 0]);
    set(handles.scrnStateString,'String','Screen Closed');
end

% Indicate whether or not the system is availble or in-use
if handles.lock
    if strcmp(get(handles.stimFncName,'string'),'Habituation')
        set(handles.lockBox,'backgroundcolor',[1 1 0]);
    else
        set(handles.lockBox,'backgroundcolor',[1 0 0]);
    end
    set(handles.useStr,'String','In Use');
else
    set(handles.lockBox,'backgroundcolor',[0 1 0]);
    set(handles.useStr,'String','System Available');
end

% Indicate whether or not alpha blending is enabled
if sio.alphaBlendingEnabled
    set(handles.alphaMaskIndicator,'Value',1);
else
    set(handles.alphaMaskIndicator,'Value',0);
end

% Indicate if there is an active warning state
if getappdata(handles.figure1,'activeWarning')
    set(handles.warningBadge,'Visible','on');
else
    set(handles.warningBadge,'Visible','off');
end

% Indicate the current state of the TTL interface.  For latency
% considerations, the interface is only validated when at application
% start or when a script/function is loaded.  Yellow means the interface is
% not valid but the user has selected to proceed and suppress warnings
ttlData = get(handles.ttlOverrideButton,'UserData');
if ttlData.isValid
    set(handles.ttlOverrideButton,'Backgroundcolor',[0 1 0]);
elseif ttlData.override
    set(handles.ttlOverrideButton,'Backgroundcolor',[1 1 0]);
else
    set(handles.ttlOverrideButton,'Backgroundcolor',[1 0 0]);
end

% Show the currently selected email notification target
addresses = handles.emailInterface.getSortedAddresses;
menuStrings = [{'Notifications Disabled'},...
    addresses,{'New Address','Remove an Address'}];
set(handles.emailAddressField,'String',menuStrings);
currentTarget = handles.emailInterface.getTargetAddress;
if isempty(currentTarget)
    strIndex = 1;
else
    strIndex = find(strcmp(addresses,currentTarget)) + 1;
end
set(handles.emailAddressField,'Value',strIndex);

% Verify logging is ready to go - yellow means that the user has selected
% to proceed without a valid logging interface and warning messages will be
% suppressed
if handles.loggingInterface.isReadyToLog
    set(handles.logOverrideButton,'Backgroundcolor',[0 1 0]);
elseif get(handles.logOverrideButton,'UserData')
    set(handles.logOverrideButton,'Backgroundcolor',[1 1 0]);
else
    set(handles.logOverrideButton,'Backgroundcolor',[1 0 0]);
end

% Subtly shade txt fields that should be set for logging but have not been
dfltBGColor = get(0,'factoryUitabBackgroundColor');
if isempty(get(handles.animalIDTxt,'String'))
    set(handles.animalIDTxt,'BackgroundColor',[1 0.9 0.9]);
else
    set(handles.animalIDTxt,'BackgroundColor',dfltBGColor);
end
if isempty(get(handles.sessionNameTxt,'String'))
    set(handles.sessionNameTxt,'BackgroundColor',[1 0.9 0.9]);
else
    set(handles.sessionNameTxt,'BackgroundColor',dfltBGColor);
end
switch get(handles.experimentDescriptionTxt,'UserData')
    case 'dirty'
        set(handles.experimentDescriptionTxt,...
            'BackgroundColor',[1 1 0.9]);
    otherwise
        set(handles.experimentDescriptionTxt,...
            'BackgroundColor',dfltBGColor);
end

% Show current log messages
appMessages = getappdata(handles.figure1,'appMessages');
[messages,timestamps] = appMessages.returnFIFO;
messages = regexprep(messages,'\n','');
messages = regexprep(messages,'TbTbTb','\n    ');
if get(handles.timestampBox,'value')
    for iM = 1:length(messages)
        messages{iM} = sprintf('%s: %s',timestamps{iM},messages{iM});
    end
end
set(handles.appText,'String',messages);
set(handles.appText,'Value',numel(get(handles.appText,'String')));

end

function closereq_withVerify(hObject,~,handles)
% Quits the application after prompting the user.  Cleans up.

openFlag = isappdata(hObject,'ScreenOpen');
delayActive = isappdata(handles.figure1,'activeTimer');
if handles.lock || openFlag || delayActive
    % Prompt the user to make sure they are ready to quit
    if handles.lock
        prompt = sprintf('Override %s lock and quit?',...
            get(handles.figure1,'Name'));
    elseif openFlag
        prompt = sprintf('Close screen window and quit %s ?',...
            get(handles.figure1,'Name'));
    elseif delayActive
        prompt = sprintf('Cancel delay timer and quit %s ?',...
            get(handles.figure1,'Name'));
    end
    if exist('prompt','var')
        selection = questdlg(prompt,...
            ['Close ' get(handles.figure1,'Name') '...'],...
            'Yes','No','Yes');
        if strcmp(selection,'No')
            return;
        end
    end
end

% Delete the all event listeners
delete(handles.evntListeners);

% Delete active timers if they exist
if delayActive
    timerStruct = getappdata(handles.figure1,'activeTimer');
    stop(timerStruct.hTimer);
    delete(timerStruct.hTimer);
end

% Deselect the user
handles.loggingInterface.currentUser = '';

% Post a notification so any existing applications will quit
notify(handles.scaEventObject,'ExitApp');

if handles.standalone
    % Close the editor window
    %desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    %jEditor = desktop.getGroupContainer('Editor').getTopLevelAncestor;
    %jEditor.dispose; % closes but will be open the next time matlab
    %launches
    % Close the editor window
    try
        editorservices.closeGroup;
    catch ME
    end
    exit
end

% Restore the matlab desktop if it is hidden
menuValue = get(handles.dtwVisibilityMenu,'Checked');
if strcmp(menuValue,'off')
    showDesktopWindow(handles);
end

% Quit the GUI
delete(handles.figure1);
end

function manualUnlock(hObject)
handles = guidata(hObject);
delayActive = isappdata(handles.figure1,'activeTimer');
if handles.lock || delayActive
    % Prompt the user to make sure they are ready to quit
    if handles.lock
        prompt = sprintf('Override %s lock?',...
            get(handles.figure1,'Name'));
    elseif delayActive
        prompt = sprintf('Cancel delay timer for %s ?',...
            get(handles.figure1,'Name'));
    end
    if exist('prompt','var')
        selection = questdlg(prompt,...
            ['Close ' get(handles.figure1,'Name') '...'],...
            'Yes','No','Yes');
        if strcmp(selection,'No')
            return;
        end
    end
    lockScrnCtrl(false,handles);
    handles.lock = false;
    guidata(hObject,handles);
    sio = getappdata(handles.figure1,'ScreenInterface');
    if sio.verifyWindow
        sio.deleteAllTextures;
        sio.flipScreen;
    end
    if isappdata(handles.figure1,'activeTimer')
        timerStruct = getappdata(handles.figure1,'activeTimer');
        if isfield(timerStruct,'hTimer')
            deleteTimers(timerStruct.hTimer);
        end
        rmappdata(handles.figure1,'activeTimer');
    end
    set(handles.execStimFncButton,'String','Execute');
    displayMessage('ScrnCtrlApp manually unlocked',handles);
    updateGUI(handles);
end
end

% -------------------------------------------------------------------------
% Use java to hide the matlab window.  This is used for standalone mode,
% may or may not be robust to matlab updates since it uses undocumented
% techniques to find and hide the window.

function dtw = findDesktopWindow()
wins = java.awt.Window.getOwnerlessWindows();
for i = 1:numel(wins)
    if isa(wins(i), 'com.mathworks.mde.desk.MLMainFrame')
        dtw = wins(i);
        return;
    end
end
end

function dtwVisibilityMenu_Callback(hObject,~,handles)
menuValue = get(hObject,'Checked');
if strcmp(menuValue,'off')
    showDesktopWindow(handles);
else
    hideDesktopWindow(handles);
end
end

function hideDesktopWindow(handles)
set(handles.dtwVisibilityMenu,'Checked','off');
handles.dtw.hide;
end

function showDesktopWindow(handles)
set(handles.dtwVisibilityMenu,'Checked','on');
handles.dtw.show;
end

% -------------------------------------------------------------------------
% External interfaces to app and screen state variables that can be used
% by stimulus rendering programs

function win = returnScreenWindow()
% Return an open screen window for an application to use - usage
% win = ScrnCtrlApp('returnScreenWindow')
win = getWindow(getappdata(ScrnCtrlApp,'ScreenInterface'));
end

function mp = returnMonitorProfile()
% Return the screen interface's monitor profile
% mp = ScrnCtrlApp('returnMonitorProfile')
mp = getMonitorProfile(getappdata(ScrnCtrlApp,'ScreenInterface'));
end

function fig = returnFigure()
handles = guidata(ScrnCtrlApp);
fig = handles.figure1;
end

function value = checkUserAbort()
% This function is slow.  Requesting event support and defining UserAbort
% event callback is better.
% value = ScrnCtrlApp('checkUserAbort')
handles = guidata(ScrnCtrlApp);
value = handles.userAbort;
end

function hObj = requestEventSupport()
% Return the event object that can be used to listen for abort signals.
% hObj = ScrnCtrlApp('requestEventSupport');
handles = guidata(ScrnCtrlApp);
hObj = handles.scaEventObject;
end

function notifyOfWarning(warnDescTxt)
handles = guidata(ScrnCtrlApp);
if ~isa(warnDescTxt,'cell')
    warnDescTxt = {warnDescTxt};
end
setappdata(handles.figure1,'activeWarning',true);
warnMsg = ['WARNING: ' warnDescTxt{:}];
displayMessage(warnMsg,handles);
handles.loggingInterface.logMessage(warnMsg);
end

function clearWarning(handles)
% Clear any old warning indication
setappdata(handles.figure1,'activeWarning',false);
set(handles.warningBadge,'Visible','off');
end

function [animalID,sessionName] = getAnimalAndSession()
% Return current AnimalID and SessionName values from GUI.
% [ID,SN] = ScrnCtrlApp('getAnimalAndSession');
handles = guidata(ScrnCtrlApp);
animalID = handles.animalIDTxt.String;
sessionName = handles.sessionNameTxt.String;
end

function acknowledgement = requestSynchronousScreenControl()
% Allow rendering functions to lock the screen while they are using it
hObject = ScrnCtrlApp;
handles = guidata(hObject);
if ~handles.lock    
    handles.lock = true;
    set(handles.userAbortButton,'Enable','on');
    handles.userAbort = false;
    acknowledgement = true;
    guidata(hObject,handles);
else
    acknowledgement = false;
end
handles.loggingInterface.flushQueue;
updateGUI(handles);
end

function releaseSynchronousScreenControl()
% Allow render functions to relinquish exclusive screen access
hObject = ScrnCtrlApp;
handles = guidata(hObject);
if handles.lock
    sio = getappdata(handles.figure1,'ScreenInterface');
    sio.setLowPriority;
    sio.deleteAllTextures;
    handles.lock = false;
    set(handles.userAbortButton,'Enable','off');
    % Play a sound to alert that the sequence has ended
    if strcmp(get(handles.audioFeedbackMenu,'checked'),'on')
        if handles.userAbort
            playAlertTone('Abort');
            handles.userAbort = false;
            guidata(hObject,handles);
        else
            playAlertTone('NormalCompletion');
            notify(handles.scaEventObject,'FunctionCompleted',...
                messageEventData('ScreenCtrlApp Completion Notice',...
                sprintf('%s',datestr(now,13))));
        end
    end
    guidata(hObject,handles);
end
updateGUI(handles);
end

function completionEvent_Callback(source,eventMessage)
% Dispatch completion event messages to the emailInterface
handles = guidata(source.hObject);
if getappdata(handles.figure1,'notifyOnCompletion')
    handles.emailInterface.sendMail(eventMessage);
end
end

function screenToggleButton_Callback(~,~,handles)
if ~handles.lock
    sio = getappdata(handles.figure1,'ScreenInterface');
    if sio.verifyWindow
        sio.closeScreen;
    else
        sio.openScreen;
    end
end
end

function toggleAlphaMaskButton_Callback(~,~,handles)
sio = getappdata(handles.figure1,'ScreenInterface');
if sio.alphaBlendingEnabled
    sio.disableAlphaBlending;
else
    sio.enableAlphaBlending;
end
end

function monitorCalibrationMenu_Callback(varargin)
screenInterfaceClass.calibrateMonitor();
end


function clearAppTextButton_Callback(~,~,handles)
appMessages = getappdata(handles.figure1,'appMessages');
appMessages.flush;
updateGUI(handles);
% messages = appMessages.returnFIFO;
% set(handles.appText,'String',messages);
% set(handles.appText,'Value',numel(messages));
end

function userAbortButton_Callback(hObject,~,handles)
handles.userAbort = true;
guidata(hObject,handles);
notify(handles.scaEventObject,'UserAbort');
end


function loadStimScriptMenu_Callback(hObject,~,handles)
% Load a stimulus script, look first in the last directory used to load a
% script
if isappdata(handles.figure1,'lastScriptPath')
    wd = cd(getappdata(handles.figure1,'lastScriptPath'));
    [filename,fncPath] = uigetfile;
    cd(wd);
else
    [filename,fncPath] = uigetfile;
end
if filename ~= 0
    % Tell existing apps to close
    notify(handles.scaEventObject,'ExitApp');
    setappdata(handles.figure1,'fncLoaded',true);
    setappdata(handles.figure1,'fncType','script');
    filename = filename(1:regexp(filename,'\.m')-1);
    setappdata(handles.figure1,'lastScriptPath',fncPath);
    % Some problem correctly setting the path to the function if it is in a
    % non-path directory. The following will force the str2func to associate
    % with the correct file
    wd = cd(fncPath);
    exist(filename,'file');
    handles.funcHandle = str2func(filename);
    guidata(hObject,handles);
    cd(wd);
    % Setup for execution
    set(handles.execStimFncButton,'Enable','on');
    set(handles.configStimFncButton,'Enable','on');
    set(handles.delayButton,'Enable','on');
    set(handles.stimFncName,'string',filename);
end
end

function loadStimFncMenu_Callback(hObject,~,handles)

configGUIForExecution = false;
switch hObject
    case handles.loadStimFncMenu
        % If called from the generic load menu item, query user for the function
        if isappdata(handles.figure1,'lastFncPath')
            wd = cd(getappdata(handles.figure1,'lastFncPath'));
            [filename,fncPath] = uigetfile;
            cd(wd);
        else
            [filename,fncPath] = uigetfile;
        end
        if filename ~= 0
            % Tell existing apps to close
            notify(handles.scaEventObject,'ExitApp');
            filename = filename(1:regexp(filename,'\.m')-1);
            setappdata(handles.figure1,'lastScriptPath',fncPath);
            % Some problem correctly setting the path to the function if it is in a
            % non-path directory. The following will force the str2func to associate
            % with the correct file
            wd = cd(fncPath);
            handles.funcHandle = str2func(filename);
            handles.hFncObj = handles.funcHandle();
            guidata(hObject,handles);
            cd(wd);
            configGUIForExecution = true;
        end
    case handles.PRGratingMenu
        % Handle specific standard function selections
        notify(handles.scaEventObject,'ExitApp');
        handles.funcHandle = @stimFnc_PRGrating;
        handles.hFncObj = handles.funcHandle();
        handles.funcHandle('useControllingEventObject',...
            handles.funcHandle(),handles.scaEventObject);
        guidata(hObject,handles);
        filename = 'Phase Reverse Grating';
        configGUIForExecution = true;
end

if configGUIForExecution
    % Close the editor window
    if handles.standalone
        try
            editorservices.closeGroup;
        catch ME
            warndlg('editorservices.closeGroup failure');
            fprintf('configGUIForExecution error\n%s\n',getReport(ME));
        end
    end
    % Setup for execution
    setappdata(handles.figure1,'fncLoaded',true);
    setappdata(handles.figure1,'fncType','function');
    set(handles.execStimFncButton,'Enable','on');
    set(handles.configStimFncButton,'Enable','on');
    set(handles.delayButton,'Enable','on');
    set(handles.stimFncName,'string',filename);
end

end

function delayButton_Callback(~,~,handles)
delayTime = round(str2double(...
    inputdlg('Enter Execution Delay Time (secs)','',1,{'0'}) ));
if delayTime == 0
    set(handles.delayButton,'String','No Delay');
else
    set(handles.delayButton,'String',sprintf('%i s delay',delayTime));
end
setappdata(handles.figure1,'delayToExecute',delayTime);
end

function execStimFncButton_Callback(~,~,handles,forceFlag)
% Force flag lets the timer callback trigger execution even though there is
% a non zero delay value selected
if nargin < 4
    forceFlag = false;
end
theStr = get(handles.execStimFncButton,'String');
disp('starting execStimFncButton_Callback');
if strcmp(theStr,'Cancel')
    % Check the string on the button.  If it is set to cancel that means
    % a timer is running and should be killed
    set(handles.executionStartStr,'Visible','off');
    timerStruct = getappdata(handles.figure1,'activeTimer');
    if isfield(timerStruct,'targetTime') % habituation timer
        displayMessage('Habituation Period Canceled',handles,true);
        set(handles.stimFncName,'string','No Stimulus Function Loaded');
        handles.lock = false;
        guidata(handles.figure1,handles);
        if ~getappdata(handles.figure1,'fncLoaded')
            set(handles.execStimFncButton,'Enable','off');
        end
        set(handles.habituateMenu,'Enable','on');
    end
    deleteTimers(timerStruct.hTimer);
    rmappdata(handles.figure1,'activeTimer');
    set(handles.execStimFncButton,'String','Execute');
    updateGUI(handles);
else
    % Clear any old warning indication
    clearWarning(handles);
    % Try running the stimulus function
    lockScrnCtrl(true,handles);
    try
        delayTime = getappdata(handles.figure1,'delayToExecute');
        if delayTime == 0 || forceFlag
            % If there is no execution delay, call the stim function immediately
            switch getappdata(handles.figure1,'fncType')
                case 'script'
                    scrFile = [getappdata(handles.figure1,'lastScriptPath') ...
                        func2str(handles.funcHandle)];
                    logStr = sprintf('ScrnCtrlApp:StartScriptExecution:%s\nAnimalID:%s,SessionName:%s',...
                        scrFile,handles.animalIDTxt.String,...
                        handles.sessionNameTxt.String);
                    handles.loggingInterface.logMessage(logStr);
                    handles.funcHandle();
                case 'function'
                    logStr = sprintf('ScrnCtrlApp:StartFunctionExecution:%s:AnimalID:%s,SessionName:%s',...
                        func2str(handles.funcHandle),...
                        handles.animalIDTxt.String,...
                        handles.sessionNameTxt.String);
                    handles.loggingInterface.logMessage(logStr);
                    handles.funcHandle('execute',handles.hFncObj);
            end
        else
            % Setup the delay timer
            delayTimer = timer('StartDelay',1,'Period',1,...
                'ExecutionMode','fixedRate');
            delayTimer.TimerFcn = ...
                @(hObject,eventData)delayStartTimer_Callback([],[],handles);
            timerStruct.hTimer = delayTimer;
            timerStruct.timeRemaining = delayTime;
            setappdata(handles.figure1,'activeTimer',timerStruct);
            str = sprintf('Execution will begin in %i seconds',delayTime);
            set(handles.executionStartStr,'String',str);
            set(handles.executionStartStr,'Visible','on');
            set(handles.execStimFncButton,'String','Cancel');
            start(delayTimer);
        end
    catch ME
        fprintf('execStimFncButton_Callback error: \nReport\n%s',getReport(ME));
    end
    lockScrnCtrl(false,handles);
end
end

function lockScrnCtrl(choice,handles)
% Disable all GUI elements that will interfere with stimulus presentation
if choice
    set(handles.execStimFncButton,'enable','off');
    set(handles.configStimFncButton,'enable','off');
    set(handles.delayButton,'enable','off');
    set(handles.stimMenu,'enable','off');
    set(handles.monitorCalibrationMenuItem,'enable','off');
else
    set(handles.execStimFncButton,'enable','on');
    set(handles.configStimFncButton,'enable','on');
    set(handles.delayButton,'enable','on');
    set(handles.stimMenu,'enable','on');
    set(handles.monitorCalibrationMenuItem,'enable','on');
end
end

function delayStartTimer_Callback(~,~,handles)
% Update the GUI to show how much time is remaining before program
% execution, then call the display function
timerStruct = getappdata(handles.figure1,'activeTimer');
tr = timerStruct.timeRemaining - 1;
if tr
    timeRemainingStr = sprintf('Execution will begin in %i seconds',tr);
    set(handles.executionStartStr,'String',timeRemainingStr);
    timerStruct.timeRemaining = tr;
    setappdata(handles.figure1,'activeTimer',timerStruct);
else
    set(handles.executionStartStr,'Visible','off');
    stop(timerStruct.hTimer);
    delete(timerStruct.hTimer);
    rmappdata(handles.figure1,'activeTimer');
    set(handles.execStimFncButton,'String','Execute');
    execStimFncButton_Callback([],[],handles,true)
end
end

function configStimFncButton_Callback(hObject,~,handles)
% Let the user control the selected function either by editing the script
% file or calling the functions configuration function
switch getappdata(handles.figure1,'fncType')
    case 'script'
        fncData = functions(handles.funcHandle);
        edit(fncData.file);
    case 'function'
        handles.hFncObj = handles.funcHandle();
        guidata(hObject,handles);
end
end

% -------------------------------------------------------------------------
% Provide an interface to the stimulus generation messaging log

function displayMessage(textStr,handles,~)
if nargin < 2 || isempty(handles)
    handles = guidata(ScrnCtrlApp);
end
appMessages = getappdata(handles.figure1,'appMessages');
appMessages.addString(textStr);
updateGUI(handles);
end

function timestampBox_Callback(~,~,handles)
% Toggle time stamping
updateGUI(handles);
end

% -------------------------------------------------------------------------
% Functions related to email notification

function handleNotificationSelectionChange(hObject)
% Activate completion notifications
values = get(hObject,'String');
selection = values{get(hObject,'Value')};
handles = guidata(hObject);
switch selection
    case 'Notifications Disabled'
        setappdata(handles.figure1,'notifyOnCompletion',false);
        handles.emailInterface.setTargetAddress([]);
    case 'New Address'
        handles.emailInterface.addNewAddressDialog;
    case 'Remove an Address'
        handles.emailInterface.removeAddressDialog;
    otherwise
        handles.emailInterface.setTargetAddress(selection);
        setappdata(handles.figure1,'notifyOnCompletion',true);
end
updateGUI(handles);
end

% -------------------------------------------------------------------------
% Functions related to user control of the hardware TTL interface

function toggleTTLOverride(hObject)
handles = guidata(hObject);
userData = get(handles.ttlOverrideButton,'UserData');
userData.isValid = handles.ttlInterface.validateInterface;
if userData.isValid
    userData.override = false;
else
    userData.override = ~userData.override;
    if userData.override
        displayMessage('User selected to override TTL system',handles);
        ttlInterfaceClass.setWarningState('ttlInterfaceClass','off');
    else
        ttlInterfaceClass.setWarningState('ttlInterfaceClass','on');
    end
end
set(handles.ttlOverrideButton,'UserData',userData);
updateGUI(handles);
end

% -------------------------------------------------------------------------
% Functions related to user selection and experimental logging

function handleUserSelectionChange(hObject)
handles = guidata(hObject.guiPopupMenu);
set(handles.animalIDTxt,'String','');
set(handles.sessionNameTxt,'String','');
set(handles.experimentDescriptionTxt,'String','');
set(handles.experimentDescriptionTxt,'UserData','clean');
updateGUI(handles);
end

function handleUserExperimentDataChange(hObject)
handles = guidata(hObject);
switch hObject
    case handles.animalIDTxt
        handles.animalIDTxt.String = ...
            regexprep(handles.animalIDTxt.String,'_','-');
    case handles.sessionNameTxt
        handles.sessionNameTxt.String = ...
            regexprep(handles.sessionNameTxt.String,'_','-');
    case handles.experimentDescriptionTxt
        if isempty(get(handles.experimentDescriptionTxt,'String'))
            set(handles.experimentDescriptionTxt,'UserData','clean');
        else
            set(handles.experimentDescriptionTxt,'UserData','dirty');
        end
end
updateGUI(handles);
end

function logUserNotes(hObject)
% Save user notes to the log immediately, but only once
handles = guidata(hObject);
if strcmp(get(handles.experimentDescriptionTxt,'UserData'),'dirty')
    userNotes = get(handles.experimentDescriptionTxt,'String');
    wasLogged = handles.loggingInterface.logMessage(userNotes);
    msgStr = 'Experimenter notes logged';
    for iN = 1:size(userNotes)
        msgStr=sprintf('%sTbTbTb%s',msgStr,userNotes(iN,:));
    end
    if wasLogged
        displayMessage(msgStr,handles,true);
        set(handles.experimentDescriptionTxt,'UserData','clean');
        set(handles.experimentDescriptionTxt,'String','');
    else
        displayMessage([msgStr(1:19) 'NOT ' msgStr(20:end)],handles,true);
    end
end
updateGUI(handles);
end

function viewExpLog(hObject)
handles = guidata(hObject);
handles.loggingInterface.getLogTable;
end

function toggleLogOverride(hObject)
handles = guidata(hObject);
set(handles.logOverrideButton,'UserData',...
    ~get(handles.logOverrideButton,'UserData'));

if get(handles.logOverrideButton,'UserData')
    handles.loggingInterface.hideWarnings(true);
    if ~handles.loggingInterface.isReadyToLog
        displayMessage('User selected to override logging system',handles);
    end
else
    handles.loggingInterface.hideWarnings(false);
end
updateGUI(handles);
end

function toggleMetadataControl(hObject,handles)
handles.ttlInterface.TTLMetaDataEnabled = hObject.Value;
end


% -------------------------------------------------------------------------
% Habituation control

function habituateMenu_Callback(~,~,handles)
% Setup a timer to be used for keeping track of habituation

% Prompt user for habituation time
habTime = round(60*str2double(...
    inputdlg('Enter Habituation Time (mins)','',1,{'30'}) ));
if isempty(habTime)
    return;
end

% Make sure the screen is open
sio = getappdata(handles.figure1,'ScreenInterface');
if ~(sio.openScreen)
    handleWarning('Screen will not open',true,'Habituation Problem');
end

% Tell existing apps to close
notify(handles.scaEventObject,'ExitApp');
setappdata(handles.figure1,'fncLoaded',false);
setappdata(handles.figure1,'fncType','');
% Close the editor window
if handles.standalone
    try
        editorservices.closeGroup;
    catch ME
        warndlg('editorservices.closeGroup failure');
        fprintf('habituateMenu_Callback error\n%s\n',getReport(ME));
    end
end

% Create the timer and start
displayMessage('Starting Habituation Period',handles,true);
theTimer = timer('StartDelay',1,'Period',1,...
    'ExecutionMode','fixedRate');
theTimer.TimerFcn = ...
    @(hObject,eventData)habituateTimer_Callback([],[],handles);
timerStruct.hTimer = theTimer;
timerStruct.timeRemaining = habTime;
timerStruct.targetTime = habTime;
setappdata(handles.figure1,'activeTimer',timerStruct);
str = sprintf('Habituation Time Remaining:\n%s',secs2Str(habTime));
set(handles.executionStartStr,'String',str);
set(handles.executionStartStr,'Visible','on');
set(handles.execStimFncButton,'String','Cancel');
if ~getappdata(handles.figure1,'fncLoaded')
    set(handles.execStimFncButton,'Enable','on');
end
set(handles.configStimFncButton,'Enable','off');
set(handles.habituateMenu,'Enable','off');
set(handles.stimFncName,'string','Habituation');
handles.lock = true;
guidata(handles.figure1,handles);
start(theTimer);
updateGUI(handles);
end

function habituateTimer_Callback(~,~,handles)
% Update GUI to show remaining habituation time
timerStruct = getappdata(handles.figure1,'activeTimer');
tr = timerStruct.timeRemaining - 1;
if tr
    timeRemainingStr = sprintf('Habituation Time Remaining:\n%s',...
        secs2Str(tr));
    set(handles.executionStartStr,'String',timeRemainingStr);
    timerStruct.timeRemaining = tr;
    setappdata(handles.figure1,'activeTimer',timerStruct);
else
    set(handles.executionStartStr,'Visible','off');
    stop(timerStruct.hTimer);
    delete(timerStruct.hTimer);
    rmappdata(handles.figure1,'activeTimer');
    set(handles.stimFncName,'string','No Stimulus Function Loaded');
    handles.lock = false;
    guidata(handles.figure1,handles);
    set(handles.execStimFncButton,'String','Execute');
    if ~getappdata(handles.figure1,'fncLoaded')
        set(handles.execStimFncButton,'Enable','off');
    end
    set(handles.habituateMenu,'Enable','on');
    msg = sprintf('Habituation completed: %s',...
        secs2Str(timerStruct.targetTime));
    notify(handles.scaEventObject,'FunctionCompleted',...
        messageEventData('Habituation Completion Notice',msg));
    displayMessage(msg,handles,true);
end
end


function closeEditorWindow
try
    allDocs = editorservices.getAll;
    if ~isempty(allDocs)
        editorservices.closeGroup;
    end
catch ME
    warndlg('editorservices failure');
    fprintf('closeEditorWindow error\n%s\n',getReport(ME));
end

end

function audioFeedbackMenu_Callback(~,~,handles)
if strcmp(get(handles.audioFeedbackMenu,'checked'),'on')
    set(handles.audioFeedbackMenu,'checked','off');
else
    set(handles.audioFeedbackMenu,'checked','on');
end
end