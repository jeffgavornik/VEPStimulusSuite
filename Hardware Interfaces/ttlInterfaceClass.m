classdef ttlInterfaceClass < storedPreferenceClass ...
        & ttlHardwareAbstractClass & classThatThrowsWarnings
    
    % Class that defines do-nothing methods so that a generic TTL interface
    % can be used for testing in hardware environments that do not support
    % the TTL interface.
    %
    % The method getTTLInterface will return the actual hardware interface
    % if one is saved in preferences
    %
    % Note: Real hardware interfaces should subclass the 
    % abstract hardwareInterfaceClass.  See usb1208FSClass for an example.
    %
    % To get the TTL interface:
    %   ttl = ttlInterfaceClass.getTTLInterface;
    % This method will return an object with class specificed by the
    % ttlHWClass property, which is stored as a preference.  To set this
    % preference, set this property to be equal to an object that inherits 
    % from the ttlHardwareAbstractClass.  Example:
    %
    % ttlObj = ttlInterfaceClass;
    % ttlObj.ttlHWClass = usb1208FSclass;
    %
    % If this property is not set, or is set incorrectly, a
    % ttlInterfaceClass object will be returned after spawning appropriate
    % warnings.
    
    %#ok<*INUSL,*MANU>
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'ttlInterfaceClass';
        dummyWarningID = 'ttlInterfaceClass:dummyObject';
        validationWarningID = 'ttlInterfaceClass:validationFailed';
        fmt = 'dd-mmm-yyyy HH:MM:SS:FFF';
    end
    
    properties (SetObservable,AbortSet)
        ttlHWClass
    end
    
    methods (Static)
        function obj = getTTLInterface
            obj = [];
            prefFile = [storedPreferenceClass.getPrefDir '/' ...
                ttlInterfaceClass.prefFileNameStr '.mat'];
            if exist(prefFile,'file') == 2
                try
                    prefs = load(prefFile);
                catch ME
                    handleWarning(ME,true,...
                        'ttlInterfaceClass:getTTLInterface failed to load file');
                end
                try
                    hwClassName = prefs.('ttlHWClass');
                    obj = eval(hwClassName);
                    if ~obj.validateInterface
                        ws =  sprintf('Class %s validateInterface failed.  Is the device plugged in?',...
                            hwClassName);
                        handleWarning(MException(ttlInterfaceClass.validationWarningID,...
                            ws),true,'TTL Interface Validation Failure');
                        obj = [];
                    end
                catch ME
                    handleError(ME,true,...
                        'ttlInterfaceClass:getTTLInterface failed to create object');
                end
            else
                if ~classThatThrowsWarnings.warningsAreSuppressedForClass('ttlInterfaceClass')
                    ME = MException('ttlInterfaceClass:noPrefs',...
                        'No ttlInterfaceClass Preference File.');
                    ws = ['File: ''',prefFile,''' does not exist. ',...
                        'Set ttlHWClass.ttlHWClass to fix'];
                    handleWarning(ME,true,ws);
                end
            end
            if isempty(obj)
                obj = ttlInterfaceClass(); % return dummy class
            end
        end
        
    end
        
    methods
        
        function obj = ttlInterfaceClass()
            obj.preferencePropertyNames = 'ttlHWClass';
            obj.listenForPreferenceChanges;
            % Warn that a dummy object is being created
            handleWarning(MException(obj.dummyWarningID,...
                'No TTL interface'),true,...
                ['ttlInterfaceClass: creating dummy interface',...
                ' No TTL data will be put on the hardware bus']);
        end
        
        function set.ttlHWClass(obj,hwInterfaceObj)
            % This method is used to set the class that will be returned
            % when a user requests a TTL hardware interface using the
            % static method getTTLInterface
            scs = superclasses(hwInterfaceObj);
            if ~sum(strcmp(scs,'ttlHardwareAbstractClass'))
                error('ttlInterface must be a subclass of hwInterfaceObj');
            end
            hwClassName = class(hwInterfaceObj);
            obj.ttlHWClass = hwClassName;
            obj.savePreferences;
        end
        
        function startRecording(obj)
            fprintf(2,'fakeTTL.startRecording %s\n',datestr(now,obj.fmt));
        end
        
        function stopRecording(obj)
            fprintf(2,'fakeTTL.stopRecording %s\n',datestr(now,obj.fmt));
        end
        
        function strobeEventWord(obj,value,varargin) 
            fprintf(2,'fakeTTL.strobeEventWord: %i %s\n',value,...
                datestr(now,obj.fmt));
        end
        
        function setEventWord(obj,value,varargin)
            fprintf(2,'fakeTTL.setEventWord: %i %s\n',value,...
                datestr(now,obj.fmt));
        end
        
        function strobe(obj,varargin) 
            fprintf(2,'fakeTTL.strobe %s\n',datestr(now,obj.fmt));
        end
        
        function isOpen = openInterface(obj)
            fprintf(2,'fakeTTL.openInterface %s\n',datestr(now,obj.fmt));
            isOpen = false;
        end
        
        function closeInterface(obj)
            fprintf(2,'fakeTTL.closeInterface %s\n',datestr(now,obj.fmt));
        end
        
        function isValid = validateInterface(obj)
            fprintf(2,'fakeTTL.validateCommunications %s\n',...
                datestr(now,obj.fmt));
            isValid = false;
        end
        
        function [minValue,maxValue] = getEventRange(obj)
            fprintf(2,'fakeTTL.getEventRange %s\n',...
                datestr(now,obj.fmt));
            minValue = 0;
            maxValue = 255;
        end
        
    end
    
end