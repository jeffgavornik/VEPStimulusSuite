classdef daqInterfaceClass < storedPreferenceClass ...
        & daqHardwareAbstractClass & classThatThrowsWarnings
        
    %#ok<*INUSL,*MANU>
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'daqInterfaceClass';
        dummyWarningID = 'daqInterfaceClass:dummyObject';
        validationWarningID = 'daqInterfaceClass:validationFailed';
    end
    
    properties (SetObservable,AbortSet)
        daqHWClass
    end
    
    methods (Static)
        function obj = getDAQInterface
            obj = [];
            prefFile = [storedPreferenceClass.getPrefDir '/' ...
                daqInterfaceClass.prefFileNameStr '.mat'];
            if exist(prefFile,'file') == 2
                try
                    prefs = load(prefFile);
                catch ME
                    handleWarning(ME,true,...
                        'daqInterfaceClass:getDAQInterface failed to load file');
                end
                try
                    hwClassName = prefs.('daqHWClass');
                    obj = eval(hwClassName);
                    if ~obj.validateInterface
                        ws =  sprintf('Class %s validateInterface failed.  Is the device plugged in?',...
                            hwClassName);
                        handleWarning(MException(daqInterfaceClass.validationWarningID,...
                            ws),true,'DAQ Interface Validation Failure');
                        obj = [];
                    end
                catch ME
                    handleError(ME,true,...
                        'daqInterfaceClass:getDAQInterface failed to create object');
                end
            else
                if ~classThatThrowsWarnings.warningsAreSuppressedForClass('daqInterfaceClass')
                    ME = MException('daqInterfaceClass:noPrefs',...
                        'No daqInterfaceClass Preference File.');
                    ws = ['File: ''',prefFile,''' does not exist. ',...
                        'Set daqHWClass.daqHWClass to fix'];
                handleWarning(ME,true,ws,[],true);
                end
            end
            if isempty(obj)
                obj = daqInterfaceClass(); % return dummy class
            end
        end
        
    end
        
    methods
        
        function obj = daqInterfaceClass()
            obj.preferencePropertyNames = 'daqHWClass';
            obj.listenForPreferenceChanges;
            % Warn that a dummy object is being created
            handleWarning(MException(obj.dummyWarningID,...
                'No DAQ interface'),true,...
                ['daqInterfaceClass: creating dummy interface',...
                ' No valid DIO or AIO for this interface']);
        end
        
        function set.daqHWClass(obj,hwInterfaceObj)
            % This method is used to set the class that will be returned
            % when a user requests a DAQ hardware interface using the
            % static method getDAQInterface
            scs = superclasses(hwInterfaceObj);
            if ~sum(strcmp(scs,'daqHardwareAbstractClass'))
                error('daqInterface must be a subclass of daqHardwareAbstractClass');
            end
            hwClassName = class(hwInterfaceObj);
            obj.daqHWClass = hwClassName;
            obj.savePreferences;
        end
        
        function success = openInterface(varargin)
            fprintf(2,'fakeDAQ.openInterface %s\n',datestr(now));
            success = false;
        end
        
        function success = writeAnalog(varargin)
            fprintf(2,'fakeDAQ.writeAnalog %s\n',datestr(now));
            success = false;
        end
        
        function data = readAnalog(varargin)
            fprintf(2,'fakeDAQ.readAnalog %s\n',datestr(now));
            data = [];
        end
        function success = writeDigital(varargin)
            fprintf(2,'fakeDAQ.writeDigital %s\n',datestr(now));
            success = false;
        end
        function data = readDigital(varargin)
            fprintf(2,'fakeDAQ.readDigital %s\n',datestr(now));
            data = [];
        end
        function isValid = validateInterface(varargin)
            fprintf(2,'fakeDAQ.validateInterface %s\n',datestr(now));
            isValid = false;
        end
        
        
    end
    
end