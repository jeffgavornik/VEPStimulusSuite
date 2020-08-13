classdef storedPreferenceClass < handle
    % Class that supports storing information in a standardized
    % preference file.  Files are saved as .mat files in the directory
    % defined by the static method storedPreferenceClass.getPrefDir()
    %
    % All properties with a name stored as a string in the optional
    % preferencePropertyNames property will automatically be saved and
    % loaded when savePreferences and loadSavedPreferences methods are
    % called on an instantiated subclass.
    
    properties (Constant,Abstract)
        % All subclasses must instantiate this abstract property and assign
        % it a unique string that will define the name of the preference
        % file associated with a new object of this class
        prefFileNameStr % string that defines the name of the preference file
    end
    
    properties (SetObservable,AbortSet)
        % Any property that will be auto-tracked via property listeners
        % must be SetObservable.  Consider using AbortSet flag to prevent
        % setting the dirty bit when a tracked property is set to its
        % current value
    end
    
    properties (Hidden=true)
        preferencePropertyNames % Empty or cell array of property name strings
        dirtyBit % Should be set when preference data has been changed but not saved
    end
    
    properties (Access=private)
        propListeners = {};
    end
    
    events
        PreferencesChanged
        IsDirty
        IsClean
    end
    
    methods (Static,Sealed=true)
        
        function directory = getPrefDir
            % Return the a string specifying the directory where
            % storedPreferenceClass object preferences are stored
            %
            % Note: should be written to work with Windows as well
            try
                switch computer
                    case {'GLNXA64','GLNX86'}
                        [~,userName] = system('whoami');
                        directory = ['/home/' userName(1:end-1) '/.matlab/StimulusSuitePrefs'];
                        retVal = exist(directory,'dir');
                        if retVal ~= 7
                            [success,msg,msgid] = mkdir(directory);
                            if ~success
                                ME = MException(msgid,msg);
                                handleWarning(ME,true,...
                                    sprintf('storedPreferenceClass.getPrefDir(): failed to make new directory ''%s''',directory));
                                directory = '';
                            end
                        end
                    case {'PCWIN','PCWIN64'}
                        error('getPrefDir is not implemented for PCs');
                    case {'MACI64'}
                        [~,userName] = system('whoami');
                        directory = ['/Users/' userName(1:end-1) '/Library/Preferences/StimulusSuite'];
                        retVal = exist(directory,'dir');
                        if retVal ~= 7
                            [success,msg,msgid] = mkdir(directory);
                            if ~success
                                ME = MException(msgid,msg);
                                handleWarning(ME,true,...
                                    sprintf('storedPreferenceClass.getPrefDir(): failed to make new directory ''%s''',directory));
                                directory = '';
                            end
                        end                        
                end
            catch ME
                warning('storedPreferenceClass:ComputerArchProblem',...
                    'storedPreferenceClass.getPrefDir() failed:\n%s',...
                    getReport(ME));
            end
        end
        
        function prefsWereDeleted = deletePreferenceFile(prefFileName)
            % Deletes the preference file after confirming with the user
            % that this should be done - allows user to delete prefs
            % without first instantiating an object
            prefsWereDeleted = false;
            try
                if exist(prefFileName,'file') == 0
                    msgbox(sprintf('Preference file %s does not exist to delete',prefFileName),...
                        'storedPreferenceClass.deletePreferences');
                    return;
                end
                choice = questdlg(...
                    ['Really delete ' prefFileName '?'], ...
                    'storedPreferenceClass.deletePreferences', ...
                    'Delete','Cancel',...
                    'Cancel');
                switch choice
                    case 'Delete'
                        delete(prefFileName);
                        prefsWereDeleted = true;
                end
            catch ME
                handleWarning(ME,true,'Delete preference file failure');
            end
        end
        
    end
    
    methods (Access=private)
        function setDirtyBit(obj) % callback for set method
            obj.dirtyBit = true;
        end
    end
    
    methods (Sealed=true)
        
    end
    
    
    methods
        
        function obj = storedPreferenceClass
            obj.loadSavedPreferences;
        end
        
        function delete(obj)
            % fprintf('delete storedPreferenceClass subclass %s\n',class(obj));
            if obj.dirtyBit
                %fprintf('delete(%s): dirtyBit=true\n',class(obj));
                obj.savePreferences;
            end
            obj.deletePropListeners;
        end
        
        function deletePropListeners(obj)
            if ~isempty(obj.propListeners)
                for iL = 1:length(obj.propListeners)
                    delete(obj.propListeners{iL});
                end
            end
        end
        
        function prefsWereDeleted = deletePreferences(obj)
            % Wrapper for the static method deletePreferenceFile
            prefsWereDeleted = ...
                storedPreferenceClass.deletePreferenceFile(obj.getPreferenceFileName);
        end
        
        function set.preferencePropertyNames(obj,value)
           % Restrict preferencePropertyNames to being either a string or
           % an cell array of strings.  Very that each string in the array
           % corresponds to a named property of the class.  If not, warn
           % the user
           if isa(value,'char')
               value = {value};
           end
           if ~isa(value,'cell')
               error('%s.preferencePropertyNames must be a string or an array of strings',class(obj));
           end
           nP = length(value);
           goodIndici = true(1,nP);
           for iP = 1:nP
               if ~isprop(obj,value{iP})
                   goodIndici(iP) = false;
                   warning('storedPreferenceClass:badPreferencePropertyName',...
                    'storedPreferenceClass.set.preferencePropertyNames: ''%s'' is not a valid property name for class %s\n',...
                    value{iP},class(obj));
               end
           end
           obj.preferencePropertyNames = value(goodIndici);
        end
        
        function listenForPreferenceChanges(obj)
            % Evoke this method in the subclass constructor to
            % automatically monitor for preference changes and set the
            % dirty bit accordingly - note, this will not catch changes to
            % the content of container.Map objects.
            if isempty(obj.preferencePropertyNames)
                return;
            end
            propNames = obj.preferencePropertyNames;
            if ~isa(propNames,'cell')
                propNames = {propNames};
            end
            % Don't listen twice if method is called more than once
            obj.deletePropListeners;
            for iP = 1:length(propNames)
                propName = propNames{iP};
                theProp = eval(sprintf('obj.%s',propName));
                if isa(theProp,'containers.Map')
                    warnStr = sprintf('storedPreferenceClass.listenForPreferenceChanges');
                    warnStr = sprintf('%s will not respond to key-value changes',warnStr);
                    warning('%s of containers.Map variable ''%s.%s''\n',...
                        warnStr,class(obj),propName);
                end
                obj.propListeners{end+1} = addlistener(obj,...
                    propNames{iP},...
                    'PostSet',@(varargin)setDirtyBit(obj));
            end
        end
        
        function set.dirtyBit(obj,value)
            % fprintf('%s.setDirtyBit=%i\n',class(obj),value);
            if ~islogical(value) && ~(value==0 || value == 1)
                error('%s.dirtyBit must be a boolean',class(obj));
            end
            obj.dirtyBit = value;
            if obj.dirtyBit
                notify(obj,'IsDirty');
            else
                notify(obj,'IsClean');
            end
        end
                
        function fileWithPath = getPreferenceFileName(obj)
            fileWithPath = [storedPreferenceClass.getPrefDir '/' obj.prefFileNameStr '.mat'];
            fileWithPath = regexprep(fileWithPath,'.mat.mat','.mat');
        end
        
        function prefStruct = readSavedPrefs(obj)
            prefStruct = struct;
            prefFile = obj.getPreferenceFileName;
            if exist(prefFile,'file') == 2
                try
                    prefStruct = load(prefFile);
                catch ME
                    warning(sprintf('%s:readSavedPrefs',class(obj)),...
                        '%s.saveMonitorProfile failed:\n%s',...
                        class(obj),getReport(ME));
                end
            end
        end
        
        function loadSavedPreferences(obj)
            % For each property defined in the preferenceVariableNames
            % structure, set the value of the property to be the value
            % stored in the preference file.
            prefs = obj.readSavedPrefs;
            nProps = length(obj.preferencePropertyNames);
            for iP = 1:nProps
                try
                    propName = obj.preferencePropertyNames{iP};
                    if isfield(prefs,propName)
                        obj.(propName) = prefs.(propName);
                    end
                catch ME
                    warning(sprintf('%s:loadSavedPreferences',class(obj)),...
                        '%s.loadSavedPreferences failed:\n%s',...
                        class(obj),getReport(ME));
                end
            end
        end
        
        function savePreferences(obj)
            % Write preferences to the preference file
            prefs = struct;
            nProps = length(obj.preferencePropertyNames);
            for iP = 1:nProps
                try
                    propName = obj.preferencePropertyNames{iP};
                    prefs.(propName) = obj.(propName);
                catch ME
                    warning(sprintf('%s:savePreferences',class(obj)),...
                        '%s.savePreferences set value failed:\n%s',...
                        class(obj),getReport(ME));
                end
            end
            try
                save(obj.getPreferenceFileName,'-struct','prefs');
                obj.dirtyBit = false;
                notify(obj,'PreferencesChanged');
            catch ME
                warning(sprintf('%s:savePreferences',class(obj)),...
                        '%s.savePreferences failed:\n%s',...
                        class(obj),getReport(ME));
            end
        end
        
    end
    
    
end