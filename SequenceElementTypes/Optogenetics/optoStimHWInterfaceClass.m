classdef optoStimHWInterfaceClass < storedPreferenceClass ...
        & optoStimHWInterfaceAbstractClass & classThatThrowsWarnings
    
    % Class that stores optogenetic stimulation hardware configuration and
    % returns the interface to the user.  If the interface is not
    % configured, a dummy object is returned that can be used for script
    % development when hardware is not available
    
    %#ok<*INUSL,*MANU>
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'optoStimHWInterfaceClass';
        dummyWarningID = 'optoStimHWInterfaceClass:dummyObject';
        validationWarningID = 'optoStimHWInterfaceClass:validationFailed';
        fmt = 'dd-mmm-yyyy HH:MM:SS:FFF';
    end
    
    properties (SetObservable,AbortSet)
        optoStimHWClass
    end
    
    methods (Static)
        function obj = getInterface
            obj = [];
            prefFile = [storedPreferenceClass.getPrefDir '/' ...
                optoStimHWInterfaceClass.prefFileNameStr '.mat'];
            if exist(prefFile,'file') == 2
                try
                    prefs = load(prefFile);
                catch ME
                    handleWarning(ME,true,...
                        'optoStimHWInterfaceClass:failed to load preference file');
                end
                try
                    hwClassName = prefs.('optoStimHWClass');
                    obj = eval(hwClassName);
                    if ~obj.validateInterface
                        ws =  sprintf('Class %s validateInterface failed.  Is the device plugged in?',...
                            hwClassName);
                        handleWarning(MException(optoStimHWInterfaceClass.validationWarningID,...
                            ws),true,'Optostimulus Interface Validation Failure');
                        obj = [];
                    end
                catch ME
                    handleError(ME,true,...
                        'optoStimHWClass:getInterface failed to create object based on stored configuration');
                end
            else
                if ~classThatThrowsWarnings.warningsAreSuppressedForClass('optoStimHWClass')
                    ME = MException('optoStimHWClass:noPrefs',...
                        'No optoStimHWClass Preference File.');
                    ws = ['File: ''',prefFile,''' does not exist. ',...
                        'Set optoStimHWClass.optoStimHWClass to fix'];
                    handleWarning(ME,true,ws,[],true);
                end
            end
            if isempty(obj)
                obj = optoStimHWInterfaceClass(); % return dummy class
            end
        end
    end
    
    methods
        
        function obj = optoStimHWInterfaceClass()
            % Create a dummy object, warn the user of such
            obj.preferencePropertyNames = 'optoStimHWClass';
            handleWarning(MException(obj.dummyWarningID,...
                'No OptoStim interface'),true,...
                ['optoStimHWInterfaceClass: creating dummy interface',...
                ' No Optogenetic Stimulation Will Occur!']);
        end
        
        function set.optoStimHWClass(obj,hwInterfaceObj)
            % This method is used to set the class that will be returned
            % when a user requests the interface using the static method
            % getInterface
            try
                scs = superclasses(hwInterfaceObj);
                if ~sum(strcmp(scs,'optoStimHWInterfaceAbstractClass'))
                    error('optoStimInterface must be a subclass of optoStimHWInterfaceAbstractClass');
                end
                hwClassName = class(hwInterfaceObj);
                obj.optoStimHWClass = hwClassName;
                obj.savePreferences;
            catch ME
                handleError(ME,true,'optoStimHWClass Configuration Failed');
            end
        end
        
    end
        
    methods
        
        function isOpen = openInterface(obj)
            fprintf(2,'fakeOptoStim.openInterface %s\n',...
                datestr(now,obj.fmt));
            isOpen = false;
        end
        
        function closeInterface(obj)
            fprintf(2,'fakeOptoStim.closeInterface %s\n',...
                datestr(now,obj.fmt));
        end
        
        function isValid = validateInterface(obj)
            fprintf(2,'fakeOptoStim.validateInterface %s\n',...
                datestr(now,obj.fmt'));
            isValid = false;
        end
        
        function success = turnLightOn(obj)
            fprintf(2,'fakeOptoStim.turnLightOn %s\n',...
                datestr(now,obj.fmt));
            success = false;
        end
        
        function success = turnLightOff(obj)
            fprintf(2,'fakeOptoStim.turnLightOff %s\n',...
                datestr(now,obj.fmt));
            success = false;
        end
        
        function success = setLightLevel(obj,level)
            fprintf(2,'fakeOptoStim.setLightLevel(%i) %s\n',...
                level,datestr(now,obj.fmt));
            success = false;
        end
                
        
    end
    
    
end