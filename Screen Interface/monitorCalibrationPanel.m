function varargout = monitorCalibrationPanel(varargin)

%#ok<*INUSL>
%#ok<*INUSD>
%#ok<*DEFNU>
%#ok<*NASGU>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gammaCorrectionPanel_OpeningFcn, ...
    'gui_OutputFcn',  @gammaCorrectionPanel_OutputFcn, ...
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


% --- Executes just before gammaCorrectionPanel is made visible.
function gammaCorrectionPanel_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for gammaCorrectionPanel
handles.output = hObject;
% Setup to control stimulus selection using a slider
set(handles.gammaSlider,'Callback',[]);
if verLessThan('matlab', '8.2')
    % This line worked with older version of matlab but no longer
    handles.slideListeners(1) = handle.listener(handles.gammaSlider,...
        'ActionEvent',@gammaSlider_listener_callBack);
    handles.slideListeners(2) = handle.listener(handles.blackSlider,...
        'ActionEvent',@blackSlider_listener_callBack);
    handles.slideListeners(3) = handle.listener(handles.whiteSlider,...
        'ActionEvent',@whiteSlider_listener_callBack);
elseif verLessThan('matlab', '8.3')
    % 'ActionEvent' works R2013b and older
    handles.slideListeners(1) = addlistener(handles.gammaSlider,...
        'ActionEvent',@gammaSlider_listener_callBack);
    handles.slideListeners(2) = addlistener(handles.blackSlider,...
        'ActionEvent',@blackSlider_listener_callBack);
    handles.slideListeners(3) = addlistener(handles.whiteSlider,...
        'ActionEvent',@whiteSlider_listener_callBack);
else
    handles.slideListeners(1) = addlistener(handles.gammaSlider,...
        'ContinuousValueChange',@gammaSlider_listener_callBack);
    handles.slideListeners(2) = addlistener(handles.blackSlider,...
        'ContinuousValueChange',@blackSlider_listener_callBack);
    handles.slideListeners(3) = addlistener(handles.whiteSlider,...
        'ContinuousValueChange',@whiteSlider_listener_callBack);
end

handles.screenListeners = [];
handles.userData = containers.Map;
handles.userData('lowResFlipTimer') = [];
% Redirect  close request function
set(handles.figure1,'CloseRequestFcn',...
    @(hObject,eventdata)closereq_Callback(hObject));
try % Get the screen interface and open it up
    handles.sio = screenInterfaceClass;
    handles.sio.openScreen;
    handles.screenListeners = addlistener(handles.sio,...
        'ScreenClosing',@(hObj,evntData)updateGUI(handles));
    handles.screenListeners(2) = addlistener(handles.sio,...
        'ScreenOpening',@(hObj,evntData)updateGUI(handles));
    handles.screenListeners(3) = addlistener(handles.sio,...
        'MonitorParametersChanged',@(hObj,evntData)updateGUI(handles));
    handles.screenListeners(4) = addlistener(handles.sio,...
        'GammaCorrectionApplied',@(hObj,evntData)updateGUI(handles));
    handles.screenListeners(5) = addlistener(handles.sio,...
        'PreferencesChanged',@(hObj,evntData)updateGUI(handles));
    handles.screenListeners(6) = addlistener(handles.sio,...
        'AlphaBlendingChanged',@(hObj,evntData)updateGUI(handles));
    % Set initial state and update the GUI
    handles.userData('sio') = handles.sio;
%     handles.gamma = handles.sio.gammaValue;
%     handles.black = handles.sio.blackSetPoint;
%     handles.white = handles.sio.whiteSetPoint;
    saveHandles(handles);
    updateGUI(handles);
catch ME
    fprintf(2,'Stim Build Error:\n%s\n',getReport(ME));
    closereq_Callback(hObject)
end

function saveHandles(handles)
guidata(handles.figure1,handles);

function varargout = gammaCorrectionPanel_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

function closereq_Callback(hObject)
handles = guidata(hObject);
if isfield(handles,'figure1')
    delete(handles.figure1);
end
delete(handles.screenListeners);
delete(handles.slideListeners);
userData = handles.userData;
theTimer = userData('lowResFlipTimer');
if isaRunningTimer(theTimer)
    stop(theTimer);
end
delete(theTimer)
if userData.isKey('mpChangeListener')
    delete(userData('mpChangeListener'));
end
if handles.sio.verifyWindow
    handles.sio.setBackgroundColor('gray');
end

function isRunning = isaRunningTimer(aTimer)
% Returns true if the passed variable is a valid and running timer
    isRunning = isa(aTimer,'timer') && ...
            isvalid(aTimer) && strcmp(get(aTimer,'Running'),'on');

function screenToggleButton_Callback(hObject, ~, handles)
% Let the user toggle the screen on and off
if handles.sio.verifyWindow
    handles.sio.closeScreen;
else
    handles.sio.openScreen;
end

function deletePrefsButton_Callback(hObject, eventdata, handles)
if deletePreferences(screenInterfaceClass)
    handles.sio.loadSavedPreferences;
    handles.sio.loadMonitorProfile();
    handles.sio.loadCalibratedGammaTable();
    handles.sio.setCalibrationFlags();
end

function toggleAlphaMaskButton_Callback(hObject,eventdata,handles)
if handles.sio.alphaBlendingEnabled
    handles.sio.disableAlphaBlending;
else
    handles.sio.enableAlphaBlending;
end
updateGUI(handles);

function updateGUI(handles)
% Populate all text fields with current state information
if handles.sio.verifyWindow
    set(handles.screenToggleButton,'Backgroundcolor',[0 1 0]);
else
    set(handles.screenToggleButton,'Backgroundcolor',[1 0 0]);
end
gamma = handles.sio.gammaValue;
white = handles.sio.whiteSetPoint;
black = handles.sio.blackSetPoint;
set(handles.gammaPanel,'Title',sprintf('Gamma = %1.2f, BP = %i, WP = %i',...
    gamma,black,white));
set(handles.gammaValue,'String',sprintf('%1.2f',gamma));
set(handles.blackValue,'String',sprintf('%i',black));
set(handles.whiteValue,'String',sprintf('%i',white));
set(handles.gammaSlider,'Value',gamma);
set(handles.blackSlider,'Value',black);
set(handles.whiteSlider,'Value',white);
set(handles.monitorNameTxt,'String',...
    sprintf('%s',handles.sio.monProfile.name));
set(handles.editWidthTxt,'String',...
    sprintf('%1.1f',100*handles.sio.monProfile.screen_width));
set(handles.editHeightTxt,'String',...
    sprintf('%1.1f',100*handles.sio.monProfile.screen_height));
set(handles.editViewingDistanceTxt,'String',...
    sprintf('%1.1f',100*handles.sio.monProfile.viewing_distance));
if handles.sio.window
    res = Screen('Resolution',handles.sio.window);
    set(handles.rowsTxt,'String',sprintf('%i rows',res.width));
    set(handles.colsTxt,'String',sprintf('%i cols',res.height));
    if res.hz == 0
        res.hz = handles.sio.getMonitorRefreshRate;
    end
    set(handles.freqTxt,'String',sprintf('%1.1f Hz',res.hz));
else
    set(handles.rowsTxt,'String','-- rows');
    set(handles.colsTxt,'String','-- cols');
    set(handles.freqTxt,'String','-- Hz');
end
set(handles.monitorFileTxt,'String',...
    ['MonitorFile:' handles.sio.monitorCalibrationFile]);
set(handles.gammaFileTxt,'String',...
    ['GammaFile:' handles.sio.gammaCorrectionFile]);
if handles.sio.alphaBlendingEnabled
    set(handles.alphaBlendingCheckbox,'Value',1)
else
    set(handles.alphaBlendingCheckbox,'Value',0)
end

% ------------------------------------------------------------------------
% Functions to edit parameters used for gamma correction

% Continuous value updates for the gamma correction sliders
function gammaSlider_listener_callBack(hObject,varargin)
gamma = get(hObject,'Value');
handles = guidata(hObject);
if gamma ~= handles.sio.gammaValue
    handles.sio.setGammaCorrection(gamma);
end

function blackSlider_listener_callBack(hObject,varargin)
blackSet = round(get(hObject,'Value'));
handles = guidata(hObject);
if blackSet ~= handles.sio.blackSetPoint
    handles.sio.setGammaCorrection([],blackSet);
end

function whiteSlider_listener_callBack(hObject,varargin)
whiteSet = round(get(hObject,'Value'));
handles = guidata(hObject);
if whiteSet ~= handles.sio.whiteSetPoint
    handles.sio.setGammaCorrection([],[],whiteSet);
end

function gammaValue_Callback(hObject, eventdata, handles)
% Use text edit boxes to set gamma correction variables
switch hObject
    case handles.gammaValue
        sliderHandle = handles.gammaSlider;
    case handles.whiteValue
        sliderHandle = handles.whiteSlider;
    case handles.blackValue
        sliderHandle = handles.blackSlider;
end
min = get(sliderHandle,'Min');
max = get(sliderHandle,'Max');
value = str2double(get(hObject,'String'));
if value < min
    value = min;
elseif value > max
    value = max;
end
switch hObject
    case handles.gammaValue
        set(handles.gammaSlider,'Value',value);
        gammaSlider_listener_callBack(handles.gammaSlider,[]);
    case handles.blackValue
        set(handles.blackSlider,'Value',value);
        blackSlider_listener_callBack(handles.blackSlider,[]);
    case handles.whiteValue
        set(handles.whiteSlider,'Value',value);
        whiteSlider_listener_callBack(handles.whiteSlider,[]);
end

function loadGammaButton_Callback(hObject, eventdata, handles)
filename = uigetfile([storedPreferenceClass.getPrefDir '/glut*.m'],...
    'Select gamma correction file');
if filename
    [~,filename] = fileparts(filename);
    handles.sio.loadCalibratedGammaTable(filename,true);
end

function saveGammaButton_Callback(hObject, eventdata, handles)
defaultName = sprintf('%s/glut%s.m',storedPreferenceClass.getPrefDir,date);
file = uiputfile(defaultName,'Create gamma correction preference file');
if file
    handles.sio.saveGammaCorrectionFile(file);
end

function autoGammaCorrectionButton_Callback(hObject, eventdata, handles)
params = autoGammaCharacterizationRoutine();
handles.sio.setGammaCorrection(params.gamma,params.bsp,params.wsp,params.glut);
defaultName = sprintf('%s/glut%s.m',storedPreferenceClass.getPrefDir,date);
file = uiputfile(defaultName,'Create gamma correction preference file');
if file
    handles.sio.saveGammaCorrectionFile(file,true);
end
% ------------------------------------------------------------------------
% Functions to edit parameters defining the physical properties of the
% stimulus monitor
function editMonitorProperties_Callback(hObject,eventdata,handles)
%fprintf('editMonitorProperties_Callback: %s\n',get(hObject,'tag'));
if strcmp(get(hObject,'Style'),'edit')
    strValue = get(hObject,'String');
    dblValue = str2double(strValue);
end
delta = 0.001; % 0.1 cm
switch hObject
    case handles.monitorNameTxt
        setMonitorProfileValue(handles.sio,'Name',strValue);
    case handles.editWidthTxt
        setMonitorProfileValue(handles.sio,'Width',dblValue/100);
    case handles.editHeightTxt
        setMonitorProfileValue(handles.sio,'Height',dblValue/100);
    case handles.editViewingDistanceTxt
        setMonitorProfileValue(handles.sio,'ViewingDistance',dblValue/100);
    case handles.increaseScreenWidthButton
        dblValue = handles.sio.monProfile.screen_width + delta;
        setMonitorProfileValue(handles.sio,'Width',dblValue);
    case handles.decreaseScreenWidthButton
        dblValue = handles.sio.monProfile.screen_width - delta;
        setMonitorProfileValue(handles.sio,'Width',dblValue);
    case handles.increaseScreenHeightButton
        dblValue = handles.sio.monProfile.screen_height + delta;
        setMonitorProfileValue(handles.sio,'Height',dblValue);
    case handles.decreaseScreenHeightButton
        dblValue = handles.sio.monProfile.screen_height - delta;
        setMonitorProfileValue(handles.sio,'Height',dblValue);
    case handles.increaseViewingDistanceButton
        dblValue = handles.sio.monProfile.viewing_distance + delta;
        setMonitorProfileValue(handles.sio,'ViewingDistance',dblValue);
    case handles.decreaseViewingDistanceButton
        dblValue = handles.sio.monProfile.viewing_distance - delta;
        setMonitorProfileValue(handles.sio,'ViewingDistance',dblValue);
end

function loadMPButton_Callback(hObject, eventdata, handles)
filename = uigetfile([storedPreferenceClass.getPrefDir '/mp_*.m'],...
    'Select monitor profile file');
if filename
    [~,filename] = fileparts(filename);
    handles.sio.loadMonitorProfile(filename,true);
end

function saveMonitorProfileButton_Callback(hObject, eventdata, handles)
defaultName = sprintf('%s/mp_%s_%s.m',...
    storedPreferenceClass.getPrefDir,get(handles.monitorNameTxt,'String'),date);
file = uiputfile(defaultName,'Create monitor profile preference file');
if file
    handles.sio.saveMonitorProfile(file);
end


% ------------------------------------------------------------------------
% Functions to select and render different types of visual stimuli that
% help with monnitor calibration

function stimSelectionChanged_Callback(hObject, eventdata, handles)
% Select visual stimulus or test pattern
oldString = get(eventdata.OldValue,'String');
newString = get(eventdata.NewValue,'String');
userData = handles.userData;
switch oldString
    case 'Grating'
        theTimer = userData('lowResFlipTimer');
        if isaRunningTimer(theTimer)
            stop(theTimer);
        end
        delete(theTimer);
        handles.sio.flipScreen;
        set(handles.flipFreq,'Enable','off');
        userData = handles.userData;
        delete(userData('mpChangeListener'));
        userData.remove('mpChangeListener');
        userData.remove('rotation');
        userData.remove('checkBox');
    case 'Sweep'
        theTimer = userData('lowResFlipTimer');
        if isaRunningTimer(theTimer)
            stop(theTimer);
        end
        delete(theTimer);
        handles.sio.flipScreen;
        set(handles.sweepTime,'Enable','off');
    case 'Black/White'
        theTimer = userData('lowResFlipTimer');
        if isaRunningTimer(theTimer)
            stop(theTimer);
        end
        delete(theTimer);
        handles.sio.flipScreen;
        userData.remove('CurrentColorWhite');
        set(handles.flipFreq,'Enable','off');
    case {'Grid','Gradient'}
        handles.sio.flipScreen;
    case 'Square'
        handles.sio.flipScreen;
        userData = handles.userData;
        delete(userData('mpChangeListener'));
        userData.remove('mpChangeListener');
end
switch newString
    case 'Gray Screen'
        handles.sio.setBackgroundColor('gray');
    case 'White Screen'
        handles.sio.setBackgroundColor('white');
    case 'Black Screen'
        handles.sio.setBackgroundColor('black');
    case 'Grating'
        set(handles.flipFreq,'Enable','on');
        userData('checkBox') = handles.rotateCheckbox;
        startGratingPresentation(handles);
    case 'Black/White'
        set(handles.flipFreq,'Enable','on');
        startBlackWhitePresentation(handles);
    case 'Sweep'
        set(handles.sweepTime,'Enable','on');
        startSweepPresentation(handles);
    case 'Grid'
        renderGrid(handles);
    case 'Square'
        renderSquare(handles);
    case 'Gradient'
        renderGradient(handles);
end
saveHandles(handles)

function flipFreq_Callback(hObject, eventdata, handles)
% Calculate the timer period based on the current GUI frequency value and
% update the render timer
freq = str2double(get(hObject,'String'));
if isnan(freq)
    set(hObject,'String','2');
    freq = 2;
end
userData = handles.userData;
theTimer = userData('lowResFlipTimer');
if freq == 0
    userData('noFlip') = true;
    timerPeriod = 0.2;
    timerPeriod = 0.017;
else
    userData('noFlip') = false;
    timerPeriod = 1/freq;
end
userData('period') = timerPeriod;
if isa(theTimer,'timer') && isvalid(theTimer)
    isRunning = strcmp(get(theTimer,'Running'),'on');
    if isRunning
        stop(theTimer);
    end
    newPeriod = timerPeriod - 1e-2;
    set(theTimer,'Period',newPeriod);
    start(theTimer);
end

function startGratingPresentation(handles)
handles.sio.setBackgroundColor('gray');
% Create the grating if needed
userData = handles.userData;
createGratingTexture(handles);
Screen('DrawTexture',handles.sio.window,userData('texture'),[],[],335);
userData('vbl') = handles.sio.flipScreen;
userData('needsTexture') = false;
userData('StimType') = 'FlipFlop';
userData('rotation') = 335;
% Create a listener for monitor profile changes
if ~userData.isKey('mpChangeListener')
    newListeners(1) = addlistener(handles.sio,...
        'MonitorParametersChanged',...
        @(hObj,evntData)createGratingTexture(handles));
    newListeners(2) = addlistener(handles.sio,...
        'PreferencesChanged',...
        @(hObj,evntData)createGratingTexture(handles));
    userData('mpChangeListener') = newListeners;
end
% Create the rendering timer
newTimer = timer('Name','LowResFlip',...
    'ExecutionMode','fixedspacing',...
    'Period',2,...
    'TimerFcn',@(src,event)renderTimer_Callback(userData));
userData('lowResFlipTimer') = newTimer;
flipFreq_Callback(handles.flipFreq,[],handles);

function createGratingTexture(handles)
%disp('createGratingTexture')
userData = handles.userData;
if userData.isKey('texture')
    oldTex = userData('texture');    
end
sin2D = make_PR_gratings(0.05,100);
texture = Screen('MakeTexture',handles.sio.window,sin2D);
userData('texture') = texture;
if exist('oldTex','var')
    Screen('Close',oldTex);
end

function startBlackWhitePresentation(handles)
userData = handles.userData;
userData('vbl') = handles.sio.setBackgroundColor('white');
userData('StimType') = 'BlackWhiteGray';
userData('CurrentColorWhite') = true;
% Create the rendering timer
newTimer = timer('Name','LowResFlip',...
    'ExecutionMode','fixedspacing',...
    'Period',2,...
    'TimerFcn',@(src,event)renderTimer_Callback(userData));
userData('lowResFlipTimer') = newTimer;
flipFreq_Callback(handles.flipFreq,[],handles);

function sweepTime_Callback(hObject, eventdata, handles)
sweepTime = str2double(get(hObject,'String'));
if isnan(sweepTime)
    set(hObject,'String','4.5');
    sweepTime = 4.5;
end
userData = handles.userData;
refreshRate = handles.sio.getMonitorRefreshRate(true);
nPoints = sweepTime * refreshRate / 2;
userData('cmdLumValues') = linspace(0,255,nPoints);
userData('nLumValues') = nPoints;
userData('currentIndex') = 1;
timerPeriod = 1/refreshRate;
userData('period') = timerPeriod;
theTimer = userData('lowResFlipTimer');
if isa(theTimer,'timer') && isvalid(theTimer)
    isRunning = strcmp(get(theTimer,'Running'),'on');
    if isRunning
        stop(theTimer);
    end
    newPeriod = timerPeriod - 1e-3;
    newPeriod = double(int8(1e3*newPeriod))*1e-3; % get rid of sub-ms accuracy
    set(theTimer,'Period',newPeriod);
    if isRunning
        start(theTimer);
    end
end

function startSweepPresentation(handles)
userData = handles.userData;
userData('StimType') = 'Sweep';
Screen('FillRect',handles.sio.window,0);
userData('vbl') = handles.sio.flipScreen;
% Create the rendering timer
newTimer = timer('Name','LowResFlip',...
    'ExecutionMode','fixedspacing',...
    'Period',2,...
    'TimerFcn',@(src,event)renderTimer_Callback(userData));
userData('lowResFlipTimer') = newTimer;
sweepTime_Callback(handles.sweepTime,[],handles);
start(newTimer);
        
function renderTimer_Callback(userData)
% Handle all drawing and flip for continuing stimulus rendering
sio = userData('sio');
switch userData('StimType')
    case 'FlipFlop'
        if userData('needsTexture')
            rotation = userData('rotation');
            if get(userData('checkBox'),'Value') == 1
                userData('rotation') = rotation + 15 * userData('period');
            end
            Screen('DrawTexture',sio.window,userData('texture'),[],[],rotation);
        end   
        if userData('noFlip')
            userData('needsTexture') = true;
        else
            userData('needsTexture') = ~userData('needsTexture');
        end
    case 'Sweep'
        lumValues = userData('cmdLumValues');
        currentIndex = userData('currentIndex');
        %  if currentIndex == 1
        %   tic;
        %  end
        newLumValue = lumValues(currentIndex);
        newIndex = currentIndex + 1;
        if newIndex > userData('nLumValues')
            % toc
            newIndex = 1;
        end
        userData('currentIndex') = newIndex;
        Screen('FillRect',sio.window,newLumValue);
    case 'BlackWhite'
        if userData('CurrentColorWhite')
            newColor = sio.monProfile.black * [1 1 1];
        else
            newColor = sio.monProfile.white * [1 1 1];
        end
        userData('CurrentColorWhite') = ~userData('CurrentColorWhite');
        Screen('FillRect',sio.window,newColor);
    case 'BlackWhiteGray'
        if userData('CurrentColorWhite') == 0
            newColor = sio.monProfile.black * [1 1 1];
            userData('CurrentColorWhite') = 1;
        elseif userData('CurrentColorWhite') == 1
            newColor = sio.monProfile.white * [1 1 1];
            userData('CurrentColorWhite') = 2;
        else
            newColor = sio.monProfile.gray * [1 1 1];
            userData('CurrentColorWhite') = 0;
        end        
        Screen('FillRect',sio.window,newColor);
end
flipTime = userData('vbl') + userData('period') - sio.slack;
if flipTime > GetSecs
    flipTime = 0;
end
userData('vbl') = sio.flipScreen(flipTime);

function renderGrid(handles)
screenNumber = handles.sio.getScreenNumber;
window = handles.sio.getWindow;
resolution = Screen('Resolution',screenNumber);
white=WhiteIndex(screenNumber);
black=BlackIndex(screenNumber);
% Create a grid
lw = 5; % line width
nDivisions = 10;
grid = zeros(2,2*(nDivisions+1));
rows = resolution.height;
cols = resolution.width;
% Define horizontal grid lines
for x = 0:nDivisions
    i1 = 2*(x+1)-1;
    i2 = i1+1;
    grid(:,i1) = [x*cols/nDivisions;0];
    grid(:,i2) = [x*cols/nDivisions;cols];
end
% Define vertical grid lines
offset = i2;
for y = 0:nDivisions
    i1 = offset+2*(y+1)-1;
    i2 = i1+1;
    grid(:,i1) = [0;y*rows/nDivisions];
    grid(:,i2) = [cols;y*rows/nDivisions];
end
% Render
handles.sio.setBackgroundColor('white');
Screen('DrawLines', window , grid,lw,[255 0 0]);
Screen('Flip',window);

function renderSquare(handles)
% Render a square that should be 10x10 cm if everything is correct
screenNumber = handles.sio.getScreenNumber;
window = handles.sio.getWindow;
resolution = Screen('Resolution',screenNumber);
black=BlackIndex(screenNumber);
% Calculate the number of pixels required for a 10x10 cm square
monProfile = handles.sio.getMonitorProfile;
smallestDim = min([monProfile.screen_height,monProfile.screen_width]);
if smallestDim<0.15
    sizeCM = 5;
else
    sizeCM = 10;
end
nXPix = sizeCM*1e-2*resolution.width/handles.sio.monProfile.screen_width;
nYPix = sizeCM*1e-2*resolution.height/handles.sio.monProfile.screen_height;
% Calculate location of square vertices
cX = round(resolution.width/2);
dX = round(nXPix/2);
cY = round(resolution.height/2);
dY = round(nYPix/2);
XVerts = [-dX,dX,  dX,dX,   dX,-dX, -dX,-dX];
YVerts = [ dY,dY,  dY,-dY, -dY,-dY, -dY,dY];
% Render to screen
handles.sio.setBackgroundColor('gray');
lc = black*[1 1 1]; % line color
Screen('DrawLines', window , [XVerts;YVerts],1,lc,[cX cY]);
txtSize = Screen('Preference', 'DefaultFontSize');
Screen('DrawText',window, sprintf('%i cm',sizeCM),...
    cX-round(5*txtSize/4),cY-dY-txtSize,lc);
Screen('DrawText',window, sprintf('%i cm',sizeCM),...
    cX+dX,cY-round(txtSize/4),lc);
Screen('Flip',window);
% Setup a listener to re-render if the monitor profile changes
userData = handles.userData;
if ~userData.isKey('mpChangeListener')
    newListeners(1) = addlistener(handles.sio,...
        'MonitorParametersChanged',...
        @(hObj,evntData)renderSquare(handles));
    newListeners(2) = addlistener(handles.sio,...
        'PreferencesChanged',...
        @(hObj,evntData)renderSquare(handles));
    userData('mpChangeListener') = newListeners;
end

function renderGradient(handles)
screenNumber = handles.sio.getScreenNumber;
window = handles.sio.getWindow;
resolution = Screen('Resolution',screenNumber);
cmdLums = repmat(linspace(0,1,resolution.width),resolution.height,1);
floatprecision = 2;
ti=Screen('MakeTexture', window,cmdLums,0,0,floatprecision);
% fprintf(2,'renderGradient - trying to set high precision float but bleh\n');
% cmdLums = repmat(linspace(0,255,resolution.width),resolution.height,1);
% ti=Screen('MakeTexture', window,cmdLums);
Screen('DrawTextures', window, ti);
Screen('Flip',window);
Screen('Close',ti);

% ------------------------------------------------------------------------
% Functions to make pretty GUI elements

function slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function editTxt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end