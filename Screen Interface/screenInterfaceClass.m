classdef screenInterfaceClass < singletonClass & storedPreferenceClass

    % screenInterfaceClass provides an easy to use access point to the
    % psychtoolbox Screen to simply stimulus generation and presentation in
    % the StimulusSuite environment
    %
    % 7/22/2015 Version 2.0: Unify monitor calibration routines 
    % under the screenInterfaceClass.calibrateMontitor, create the
    % interface as a subclass of the singletonClass and 
    % storedPreferenceClass, and use event notifications to broadcast
    % state changes
    
    events
        ScreenOpening
        ScreenClosing
        MonitorParametersChanged
        GammaCorrectionApplied
        AlphaBlendingChanged
        TexturesCleared
    end
    
    properties
        window % render location
        slack % screen flip interval estimate
    end
    
    properties (Constant,Hidden=true)
        defaultWhite = 255;
        defaultBlack = 0;
        defaultGray = 127;
    end
    
    properties
        black
        white
        gray
    end
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'screenInterfaceClass.mat';
        versionID = 2.0;
        userDefinedStr = 'User Defined';
        defaultMonProfStr = 'defaultMonitorProfile';
        defaultGammaStr = 'defaultGammaCorrection';
    end
    
    properties (Hidden=true)
        % OS-specific priority value
        maxPriority
        % Monitor calibration items
        calibrationFlags  
        monProfile
        gammaTable
        gammaValue
        blackSetPoint
        whiteSetPoint
        glutSpecified = false;
        monitorCalibrationFile
        gammaCorrectionFile
        alphaBlending = false;
        alphaMaskObject
        needsPreRender = true;
        % Allow a user to specify specfic actions that should be taken
        % prior to every screen flip command
        preFlipActions
        % Provide support for keeping track of purpose-specified textures
        textureDict
    end
    
    methods (Static)
        % Instance-independent methods to get and delete the interface
        % object
        
        function sio = returnInterface
            sio = [];
            try %#ok<TRYNC>
                userData = get(0,'UserData');
                sio = userData(screenInterfaceClass.singletonDesignatorKey);
            end
            if isempty(sio)
                sio = screenInterfaceClass;
            end
        end
        
        function deleteInterface
            delete(screenInterfaceClass);
        end
        
        function calibrateMonitor
            % Launch the monitorCalibrationPanel tool
            monitorCalibrationPanel;
        end
        
        function monProfile = monitorProfile
            sio = screenInterfaceClass.returnInterface;
            monProfile = getMonitorProfile(sio);
        end
        
    end
    
    methods
        
        function obj = screenInterfaceClass
            if obj.singletonNeedsConstruction
                obj.window = [];
                obj.monProfile = [];
                obj.gammaTable = [];
                obj.slack = 0;
                obj.loadSavedPreferences;
                obj.loadMonitorProfile();
                obj.loadCalibratedGammaTable();
                obj.setCalibrationFlags();
                obj.alphaMaskObject = defaultGaussianMask;
                obj.textureDict = containers.Map;
                obj.preFlipActions = containers.Map;
            end
        end
        
        function delete(obj)
            obj.closeScreen();
            % If any parameters are UserDefined, prompt the user to save
            % or loose them forever?
        end
        
        % -----------------------------------------------------------------
        % Methods to manage user defined preferences
        % -----------------------------------------------------------------
        
        function loadSavedPreferences(obj)
            % Look for a saved preference file.  If it exists, use it to
            % select the monitorCalibrationFile and gammaCorrectionFile.
            % Override default superclass method to allow for includsion of
            % default behavior.
            prefs = obj.readSavedPrefs;
            % If there were any problems finding or loading the preference
            % file, select the default calibration option.
            if isfield(prefs,'monitorCalibrationFile')
                obj.monitorCalibrationFile = prefs.monitorCalibrationFile;
            else
                obj.monitorCalibrationFile = obj.defaultMonProfStr;
            end
            if isfield(prefs,'gammaCorrectionFile')
                obj.gammaCorrectionFile = prefs.gammaCorrectionFile;
            else
                obj.gammaCorrectionFile = obj.defaultGammaStr;
            end
        end
        
        function savePreferences(obj,saveMonCalFlag,saveGammaFlag)
            % Write preferences to the preference file
            % Override superclass method to allow for saving only a sub-set
            % of the preferences
            if nargin < 2 || isempty(saveMonCalFlag)
                saveMonCalFlag = true;
            end
            if nargin < 3 || isempty(saveGammaFlag)
                saveGammaFlag = true;
            end
            prefs = obj.readSavedPrefs;
            if saveMonCalFlag
                prefs.monitorCalibrationFile = obj.monitorCalibrationFile;
            end
            if saveGammaFlag
                prefs.gammaCorrectionFile = obj.gammaCorrectionFile;
            end
            save(obj.getPreferenceFileName,'-struct','prefs');
            notify(obj,'PreferencesChanged');
        end
        
        % -----------------------------------------------------------------
        % Methods to manage monitor and gamma correction parameters
        % -----------------------------------------------------------------
        
        function setCalibrationFlags(obj)
            % If the default monitor profile or gamma correction is being
            % used, mark calibration as false.  Otherwise, calibration is 
            % assumed
            obj.calibrationFlags(1) = ...
                ~strcmp(obj.monitorCalibrationFile,obj.defaultMonProfStr);
            obj.calibrationFlags(2) = ...
                ~strcmp(obj.gammaCorrectionFile,obj.defaultGammaStr);
        end
        
        function setMonitorProfileValue(obj,tag,value)
            % Dynamically set monitor profile values (used by the
            % calibration routine)
            switch lower(tag)
                case 'viewingdistance'
                    obj.monProfile.viewing_distance = value;
                case 'height'
                    obj.monProfile.screen_height = value;
                case 'width'
                    obj.monProfile.screen_width = value;
                case 'name'
                    %obj.monitorName = value;
                    obj.monProfile.name = value;
                case 'white'
                    obj.monProfile.white = value;
                case 'black'
                    obj.monProfile.black = value;
                case 'gray'
                    obj.monProfile.gray = value;
                otherwise
                    warning('screenInterfaceObj:setMonitorProfileFail',...
                    'unknown profile tag %s',tag)
            end
            obj.monitorCalibrationFile = obj.userDefinedStr;
            notify(obj,'MonitorParametersChanged');
        end
        
        function value = getMonitorProfileValue(obj,tag)
            if isfield(obj.monProfile,tag)
                value = obj.monProfile.(tag);
            else
                warning('screenInterfaceObj:getMonitorProfileFail',...
                    'unknown profile tag %s',tag);
                value = [];
            end
        end
        
        function saveMonitorProfile(obj,monitorProfileFileName,screenNumber)
            % Writes the current monitor profile variables to a file and
            % sets that file as the default to load for future
            % screenInterfaceClass objects
            %
            % Note: the monitorProfile will be created in the directory
            % specified by screenInterface.getPrefDir() even if a different
            % path is specified in the passed monitorProfileFileName
            try
                [~,name] = fileparts(monitorProfileFileName);
                if verLessThan('matlab', '8.3')
                    warning(['screenInterfaceClass.saveMonitorProfile: '...
                        'Unable to verify valid file name due to ' ...
                        'pre-R2014a matlab version']);
                else
                    name = matlab.lang.makeValidName(name);
                end
                monitorProfileFileName = fullfile(obj.getPrefDir,[name '.m']);
                [fid,msg] = fopen(monitorProfileFileName,'w+');
                if fid == -1
                    error('screenInterfaceObj:saveMonitorProfileFail',...
                        'file %s failed to open with msg %s',...
                        monitorProfileFileName,msg);
                end
                fprintf(fid,'function monitorProfile = %s\n',name);
                fprintf(fid,'%% Autogenerated by screenInterfaceClass.saveMonitorProfile\n');
                fprintf(fid,'%% screenInterfaceClass Version ID = %1.1f\n',obj.versionID);
                fprintf(fid,'%% %s\n',datestr(now,'mmm.dd,yyyy HH:MM:SS'));
                fprintf(fid,'monitorProfile = struct;\n');
                fprintf(fid,'monitorProfile.name = ''%s''; %% monitor type\n',...
                    obj.monProfile.name);
                fprintf(fid,'monitorProfile.screen_height = %1.3f; %% meters\n',...
                    obj.monProfile.screen_height);
                fprintf(fid,'monitorProfile.screen_width = %1.3f; %% meters\n',...
                    obj.monProfile.screen_width);
                fprintf(fid,'monitorProfile.viewing_distance = %1.3f; %% meters\n',...
                    obj.monProfile.viewing_distance);
                if nargin < 3
                    screenNumber = max(Screen('Screens'));
                end
                fprintf(fid,'monitorProfile.number = %i; %% screen number\n',screenNumber);
                fprintf(fid,'%% The following are legacy parameters no longer used\n');
                fprintf(fid,'%% These parameters should be obtained dynamically\n');
                res = Screen('Resolution',screenNumber);
                fprintf(fid,'monitorProfile.rows = %i; %% pixels\n',res.height);
                fprintf(fid,'monitorProfile.cols = %i; %% pixels\n',res.width);
                fprintf(fid,'monitorProfile.hz = %i; %% refresh rate\n',res.hz);
                fprintf(fid,'monitorProfile.white = %i; %% white value\n',obj.monProfile.white);
                fprintf(fid,'monitorProfile.black = %i; %% black value\n',obj.monProfile.black);
                fprintf(fid,'monitorProfile.gray = %i; %% gray value\n',obj.monProfile.gray);
                fprintf(fid,'monitorProfile.description = ''No Description''; %% profile description\n');
                fclose(fid);
                obj.monitorCalibrationFile = name;
                obj.savePreferences(true,false);
            catch ME
                warning('screenInterfaceObj:saveMonitorProfileFail',...
                    'screenInterfaceClass.saveMonitorProfile failed:\n%s',...
                    getReport(ME));
            end
        end
        
        function set.white(obj,val)
            setMonitorProfileValue(obj,'white',val);
        end
        
        function set.black(obj,val)
            setMonitorProfileValue(obj,'black',val);
        end
        
        function set.gray(obj,val)
            setMonitorProfileValue(obj,'gray',val);
        end
        
        function val = get.white(obj)
            if isempty(obj.monProfile)
                val = obj.defaultWhite;
            else
                val = obj.monProfile.white;
            end
        end
        
        function val = get.black(obj)
            if isempty(obj.monProfile)
                val = obj.defaultBlack;
            else
                val = obj.monProfile.black;
            end
        end
        
        function val = get.gray(obj)
            if isempty(obj.monProfile)
                val = obj.defaultGray;
            else
                val = obj.monProfile.gray;
            end
        end
        
        function loadMonitorProfile(obj,monitorProfileFileName,saveChangeFlag)
            % Read stored monitor profile information from 
            % monitorProfileFileName.  If saveChangeFlag is set (default 
            % false) will also updat the stored preferences to use
            % monitorProfileFileName as the default profile
            if nargin == 1
                monitorProfileFileName = obj.monitorCalibrationFile;
            end
            if nargin < 3
                saveChangeFlag = 0;
            end
            try
                oldDir = pwd;
                if exist(monitorProfileFileName,'file') ~= 0
                    monitorProfile = eval(monitorProfileFileName);
                else
                    cd(obj.getPrefDir);
                    monitorProfile = eval(monitorProfileFileName);
                    cd(oldDir);
                end
                obj.monProfile = monitorProfile;
                obj.monitorCalibrationFile = monitorProfileFileName;
                if saveChangeFlag
                    obj.savePreferences(true,false);
                end
            catch ME
                warning('screenInterfaceObj:loadMonitorProfile',...
                    'loadMonitorProfile failed for %s:\n%s',...
                    monitorProfileFileName,getReport(ME));
                cd(oldDir);
            end
        end
        
        function loadDefaultGammaTable(obj,changeSettingFlag)
            % Force loading of the default (uncalibrated) linear gamma
            % table.  If changeSettingFlag is set to zero, the
            % gammaCorrectionFile property will not be changed
            Screen('LoadNormalizedGammaTable',...
                obj.window,repmat(linspace(0,1,256)',1,3));
            if nargin == 1 || changeSettingFlag
                obj.gammaCorrectionFile = obj.defaultGammaStr;
            end
            obj.glutSpecified = false;
            notify(obj,'GammaCorrectionApplied');
        end
        
        function loadCalibratedGammaTable(obj,gammaCorrectionFileName,saveChangeFlag)
            % Read parameters from the gammaCorrectionFile and use to set
            % gamma correction
            if nargin == 1
                gammaCorrectionFileName = obj.gammaCorrectionFile;
            end
            if nargin < 3
                saveChangeFlag = 0;
            end
            try
                oldDir = pwd;
                if obj.verifyWindow()
                    if exist(gammaCorrectionFileName,'file') ~= 0
                        gammaParams = eval(gammaCorrectionFileName);
                    else
                        cd(obj.getPrefDir);
                        gammaParams = eval(gammaCorrectionFileName);
                        cd(oldDir);
                    end
                    obj.gammaValue = gammaParams.gamma;
                    obj.blackSetPoint = gammaParams.blackSetPoint;
                    obj.whiteSetPoint = gammaParams.whiteSetPoint;
                    % If the parameter structure has a glut, use it.
                    % Otherwise construct a new glut based on the params
                    if isfield(gammaParams,'glut')
                        obj.gammaTable = gammaParams.glut;
                        obj.glutSpecified = true;
                    else
                        obj.gammaTable = makeGrayscaleGammaTable(...
                            gammaParams.gamma,...
                            gammaParams.blackSetPoint,...
                            gammaParams.whiteSetPoint);
                        obj.glutSpecified = false;
                    end
                    Screen('LoadNormalizedGammaTable',...
                        obj.window,obj.gammaTable);
                    obj.gammaCorrectionFile = gammaCorrectionFileName;
                    notify(obj,'GammaCorrectionApplied');
                    if saveChangeFlag
                        obj.savePreferences(false,true);
                    end
                end
            catch ME
                warning('screenInterfaceObj:applyGammaCorrection',...
                    'screenInterfaceClass.applyGammaCorrection failed:\n%s',...
                    getReport(ME));
                cd(oldDir);
            end
        end
       
        function setGammaCorrection(obj,gamma,blackSetPoint,whiteSetPoint,glut)
            % Create and load a gamma correction table for a specified 
            % gamma and black/white setpoints
            if obj.verifyWindow()
                if nargin < 2 || isempty(gamma)
                    gamma = obj.gammaValue;
                end
                if nargin < 3 || isempty(blackSetPoint)
                    blackSetPoint = obj.blackSetPoint;
                end
                if nargin < 4 || isempty(whiteSetPoint)
                    whiteSetPoint = obj.whiteSetPoint;
                end
                if nargin < 5
                    obj.gammaTable = ...
                        makeGrayscaleGammaTable(gamma,...
                        blackSetPoint,...
                        whiteSetPoint);
                    obj.glutSpecified = false;
                else
                    obj.gammaTable = glut;
                    obj.glutSpecified = true;
                end
                Screen('LoadNormalizedGammaTable',...
                    obj.window,obj.gammaTable);
                obj.gammaValue = gamma;
                obj.blackSetPoint = blackSetPoint;
                obj.whiteSetPoint = whiteSetPoint;
                obj.gammaCorrectionFile = obj.userDefinedStr;
                notify(obj,'GammaCorrectionApplied');
            end
        end
        
        function saveGammaCorrectionFile(obj,gammaCorrectionFileName,saveGlutFlag)
            % Writes the gamma correction parameters to a file and
            % sets that file as the default to load for future
            % screenInterfaceClass objects
            %
            % Note: the gammaCorrection file will be created in the directory
            % specified by screenInterface.getPrefDir() even if a different
            % path is specified in the passed monitorProfileFileName
            if nargin < 3
                saveGlutFlag = false;
            end
            try
                [~,name] = fileparts(gammaCorrectionFileName);
                name = matlab.lang.makeValidName(name);
                gammaCorrectionFileName = fullfile(obj.getPrefDir,[name '.m']);
                [fid,msg] = fopen(gammaCorrectionFileName,'w+');
                if fid == -1
                    error('screenInterfaceObj:saveGammaCorrectionFile',...
                        'file %s failed to open with msg %s',...
                        gammaCorrectionFileName,msg);
                end
                fprintf(fid,'function gammaPrefs = %s\n',name);
                fprintf(fid,'%% Autogenerated by screenInterfaceClass.saveGammaCorrectionFile\n');
                fprintf(fid,'%% screenInterfaceClass Version ID = %1.1f\n',obj.versionID);
                fprintf(fid,'%% %s\n',datestr(now,'mmm.dd,yyyy HH:MM:SS'));
                fprintf(fid,'gammaPrefs = struct;\n');
                fprintf(fid,'gammaPrefs.gamma = %f;\n',obj.gammaValue);
                fprintf(fid,'gammaPrefs.blackSetPoint = %f;\n',obj.blackSetPoint);
                fprintf(fid,'gammaPrefs.whiteSetPoint = %f;\n',obj.whiteSetPoint);
                if saveGlutFlag
                    glut = obj.gammaTable;
                    fprintf(fid,'gammaPrefs.glut = [ ...\n');
                    nRows = size(glut,1);
                    for iR = 1:nRows
                        fprintf(fid,'\t%i,%i,%i;...\n',...
                            glut(iR,1),glut(iR,2),glut(iR,3));
                    end
                    fprintf(fid,'\t];\n');
                end
                fclose(fid);
                obj.gammaCorrectionFile = name;
                obj.savePreferences(false,true);
            catch ME
                warning('screenInterfaceObj:saveMonitorProfileFail',...
                    'saveMonitorProfile failed:\n%s',...
                    getReport(ME));
            end
        end
        
        % -----------------------------------------------------------------
        % Methods to manage screen windows
        % -----------------------------------------------------------------
        function calibrationFlag = openScreen(obj,SkipSyncTests)
            
            % If there is already an open window, return existing
            % calibration flag
            if obj.verifyWindow
                calibrationFlag = prod(obj.calibrationFlags);
                return
            end
            
            % Open the window and get its properties - if the default
            % monitor profile is being used and there is only one monitor
            % attached to the screen, a small window is opened in the
            % upper-left hand cornere of the monitor for debugging and
            % development
            debugConfig = obj.monProfile.number == 0;
            if nargin < 2
                SkipSyncTests = 0;
            end
            if debugConfig
                rect = [0 0 720 450];
                Screen('Preference', 'SkipSyncTests', 1);
            else
                rect = [];
                Screen('Preference', 'SkipSyncTests', SkipSyncTests);
            end
            
            try
                PsychImaging('PrepareConfiguration');
                PsychImaging('AddTask', 'General', ...
                    'FloatingPoint32BitIfPossible');
                %PsychImaging('FinalizeConfiguration');
                obj.window = PsychImaging('OpenWindow', ...
                    obj.monProfile.number, obj.monProfile.gray,rect);
            catch ME
                handleError(ME,true,'Psychimaging Problem, try again');
                %obj.window = Screen('OpenWindow',...
                %    obj.monProfile.number,obj.monProfile.gray,rect);
            end
            Screen('Flip',obj.window);
            obj.getMaxPriorityForSystem();
            obj.slack = 0.5*Screen(obj.window,'GetFlipInterval');
            
            % Correct rows/cols when in debug mode
            if debugConfig
                [width, height]=Screen('DisplaySize',0);
                mp = obj.monProfile;
                [cols,rows] = Screen('WindowSize',0);
                colRatio = rect(4)/cols;
                rowRatio = rect(3)/rows;
                [cols,rows] = Screen('WindowSize',obj.window);
                mp.rows = rows;
                mp.cols = cols;
                mp.screen_height = height * rowRatio * 1e-3;
                mp.screen_width = width * colRatio * 1e-3;
                obj.monProfile = mp;
            end
            
            % Apply gamma correction and set the calibration state
            obj.loadCalibratedGammaTable();
            obj.setCalibrationFlags();
            calibrationFlag = prod(obj.calibrationFlags);
            
            % Warn the user if the calibration state is false
            if ~calibrationFlag && ~debugConfig
                prompt = sprintf('Screen Interface: Calibration Problems\n');
                if ~obj.calibrationFlags(1)
                    prompt = sprintf('%s No calibrated monitor profile\n',prompt);
                end
                if ~obj.calibrationFlags(2)
                    prompt = sprintf('%s No calibrated gamma correction\n',prompt);
                end
                prompt = sprintf('%s THIS MAY RESULT IN INCORRECT STIMULI\n',prompt);
                prompt = sprintf('%sRun screenInterfaceClass.calibrateMonitor to correct',prompt);
                uiwait(warndlg(prompt,'screenInterfaceClass:Uncalibrated','modal'));
            end
            
            % If alpha blending was enabled when the screen closed, the
            % flag will still be set but blending will not be enabled on
            % the reopened screen.  In this case, re-enable.
            if obj.alphaBlending
                obj.enableAlphaBlending('',true);
            end
            
            % Post notification that the screen is opening
            notify(obj,'ScreenOpening');
            
        end
        
        function closeScreen(obj)
            if ~obj.verifyWindow()
                return;
            end
            try
                % load default gamma table so that the monitor doesn't look
                % strange after the window closes
                obj.loadDefaultGammaTable(0);
                Screen('closeall');
                obj.window = [];
            catch ME
                warning('screenInterfaceObj:closeFail',...
                    'closeScreen failed:\n%s',...
                    getReport(ME));
            end
            obj.slack = 0;
            notify(obj,'ScreenClosing');
        end
        
        function window = getWindow(obj)
            % Return an open window
            if ~verifyWindow(obj)
                openScreen(obj);
            end
            window = obj.window;
        end
        
        function res = getScreenResolution(obj,screenNumber)
            if nargin == 1 || isempty(screenNumber)
                screenNumber = obj.getScreenNumber;
            end
            res = Screen('Resolution',screenNumber);
        end
        
        function screenNumber = getScreenNumber(obj)
            screenNumber = obj.monProfile.number;
        end
        
        function monProfile = getMonitorProfile(obj)
            monProfile = obj.monProfile;
        end
        
        function keyValue = addPreFlipAction(obj,keyValue,fncHandle)
            [tf,~,ME] = isfunction(fncHandle);
            if ~tf
                ws = sprintf('%s.addPreFlipAction bad fndHandle for key %s',...
                    class(obj),keyValue);
                handleWarning(ME,true,ws);
                keyValue = '';
                return;
            end
            if obj.preFlipActions.isKey(keyValue)
                keyValue = [keyValue '_'];
            end
            obj.preFlipActions(keyValue) = fncHandle;
        end
        
        function removePreFlipAction(obj,keyValue)
            if ~obj.preFlipActions.isKey(keyValue)
                ME = MException('screenInterfaceClass:badKey',...
                    'Bad preFlipAction key');
                ws = sprintf('''%s'' is not a preFlipActions key',keyValue);
                handleWarning(ME,false,ws);
            end
            obj.preFlipActions.remove(keyValue);
        end
        
        
        function executePreFlipFncs(obj)
            % Call this to get a jump on pre-flip rendering operations or
            % if pre-flip functions are wanted but flipScreen is not being
            % used
            if ~obj.needsPreRender
                return;
            end
            preFlipFncs = obj.preFlipActions.values;
            for iF = 1:length(preFlipFncs)
                fncHandle = preFlipFncs{iF};
                try
                    fncHandle();
                catch ME
                    warnStr = sprintf('%s.flipScreen preFlipFnc fail for %s',...
                        class(obj),func2str(fncHandle));
                    handleWarning(ME,false,warnStr);
                    keys = obj.preFlipActions.keys;
                    obj.preFlipActions.remove(keys{iF});
                end
            end
            obj.needsPreRender = false;
        end
        
        function vbl = flipScreen(obj,varargin)
            % This call will automatically render the alpha mask if it is
            % enabled before executing the flip command
            obj.executePreFlipFncs;
            vbl = Screen('flip',obj.window,varargin{:});
            obj.needsPreRender = true;
        end

        function deleteAllTextures(obj)
            % Delete all Screen textures and post a notification so that
            % listeners can regenerate their textures if needed
            Screen('close'); 
            notify(obj,'TexturesCleared');
        end
        
        function tex = makeTexture(obj,matrix,window)
            if nargin < 3 || isempty(window)
                window = obj.window;
            end
            tex = [];
            try
                tex = Screen('MakeTexture',window,matrix);
            catch ME
                handleWarning(ME,1,'MakeTexture failure');
            end
        end
        
        
        function [refreshRate,monitorFlipInterval] = getMonitorRefreshRate(obj,forceFlag)
            % Try to read the screen refresh frequency with 
            % Screen('FrameRate')  If this fails (which it does on Macs), 
            % or forceFlag is set, use alternate approach based on 
            if nargin < 2
                forceFlag = true;
            end
            refreshRate = [];
            monitorFlipInterval = [];
            if obj.verifyWindow
                refreshRate = Screen('FrameRate',obj.window);
                if refreshRate == 0 || forceFlag
                    monitorFlipInterval = Screen('GetFlipInterval',...
                       obj.window);
                    refreshRate = 1/monitorFlipInterval;
                else
                    monitorFlipInterval = 1/refreshRate;
                end
            end
        end
        
        function windowIsValid = verifyWindow(obj)
            % Returns true if the window is open and ready for use, false
            % otherwise (e.g. window closed due to incorrect Screen
            % command)
            windowIsValid = ~(isempty(obj.window) || ...
                Screen(obj.window,'WindowKind') == 0);
        end
        
        function vbl = setBackgroundColor(obj,color)
            % Allow commanded changes to the background window color.
            % Color can be strings 'white', 'black' and 'gray' or a number
            % between 0 and 255
            if isa(color,'char')
                switch lower(color)
                    case 'white'
                        cmdLuminance = obj.monProfile.white * [1 1 1];
                    case 'black'
                        cmdLuminance = obj.monProfile.black * [1 1 1];
                    case 'gray'
                        cmdLuminance = obj.monProfile.gray * [1 1 1];
                    otherwise
                        return
                end
            else
                cmdLuminance = color;
            end
            win = obj.getWindow;
            Screen('FillRect',win,cmdLuminance);
            vbl = obj.flipScreen;
        end        
        
        % ----------------------------------------------------------------
        % Provide support for alpha blending to create masking textures
        % Note: the default behavior is to use the alphaMaskObject whenever
        % alpha blending is enabled.  The mask can be deactivated by using
        % alphaMaskClass.disableMask (which is called by the toggleMask
        % method)
        % -----------------------------------------------------------------
        
        function enableAlphaBlending(obj,blendType,skipNotify)
            % Enable alpha mask blending, see Screen('BlendFunction?') for
            % valid blend types.  Default is GL_ONE_MINUS_SRC_ALPHA
            if obj.verifyWindow
                if nargin < 2 || isempty(blendType)
                    blendType = GL_ONE_MINUS_SRC_ALPHA; %GL_ONE
                end
                Screen('BlendFunction',obj.window,...
                    GL_SRC_ALPHA,blendType);
                obj.alphaBlending = true;
                obj.addPreFlipAction('AlphaMasking',...
                    @(hObj)renderMask(obj.alphaMaskObject));
                if nargin < 3 || skipNotify ~= true
                    notify(obj,'AlphaBlendingChanged');
                end
            end
        end
        
        function disableAlphaBlending(obj)
            if obj.verifyWindow
                Screen('BlendFunction',obj.window,...
                    GL_ONE,GL_ZERO);
                obj.alphaBlending = false;
                obj.removePreFlipAction('AlphaMasking')
                notify(obj,'AlphaBlendingChanged');
            end
        end
        
        function isEnabled = alphaBlendingEnabled(obj)
            isEnabled = obj.alphaBlending;
        end
        
        function set.alphaMaskObject(obj,maskObject)
            % Verify that the maskObject is a subclass of the
            % alphaMaskClass
            scs = superclasses(maskObject);
            if ~sum(strcmp(scs,'alphaMaskClass'))
                error('alphaMaskObject must be a subclass of alphaMaskClass');
            end
            obj.alphaMaskObject = maskObject;
        end
        
        function toggleMask(obj)
            if obj.alphaMaskObject.isEnabled
                obj.alphaMaskObject.disableMask;
            else
                obj.alphaMaskObject.enableMask;
            end
        end
        
        function maskObj = getAlphaMaskObject(obj)
            maskObj = obj.alphaMaskObject;
        end
        
        % -----------------------------------------------------------------
        % Allow user to toggle between max and min timing priority for
        % Screen flip commands
        % -----------------------------------------------------------------
        function setHighPriority(obj)
            Priority(obj.maxPriority);
        end
        
        function setLowPriority(~)
            Priority(0);
        end
        
        function getMaxPriorityForSystem(obj)
            switch computer
                case {'GLNX86','GLNXA64'}
                    obj.maxPriority = 50; % note: officially up to 99 but this doesn't work
                otherwise
                    obj.maxPriority = MaxPriority(obj.window);
            end
        end
        
    end
    
end