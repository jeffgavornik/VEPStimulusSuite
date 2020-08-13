classdef nidaq_USB6221 < singletonClass ...
        & ttlHardwareAbstractClass ...
        & storedPreferenceClass ...
        & classThatThrowsWarnings
    
    % Notes: 
    % Uses daq toolbox
    
    % TTL interface defines start, stop and strobe bits as well as an 8-bit
    % data word
    
    
    properties (Constant,Hidden=true)
        configErrorID = 'nidaq_usb6221:CONFIG';
        archWarningID = 'nidaq_usb6221:ARCH';
        statusWarningID = 'nidaq_usb6221:badStatus';
    end
    
    properties (SetObservable,AbortSet)
        port
        board
    end
    
    properties (Hidden=true)
        % For error/warning messages
        useGUI = true;
    end
    
    properties (Hidden=true)
        dev % the device, set by openInterface method
    end
    
    properties (Constant)
        supportedArchs = {'GLNX86','GLNXA64','MACI64'};
        % Define control signal locations % NEEDS WRITING
        TTLSTARTPIN = 'D2';
        TTLSTROBEPIN = 'D3';
        % Define DIO bits for event word
        TTLEVNTPINS = {'D4' 'D5' 'D6' 'D7' 'D8' 'D9' 'D10' 'D11'};
        OPENDIOPINS = {'D13' 'D14'};
    end
    
    methods
        
        function obj = nidaq_USB6221(port,board)
            % Open the interface - dev property will be
            % empty the first time the constructor is called. In subsequent
            % calls it will not be empty due to the singleton superclass
            % constructor
            if obj.singletonNeedsConstruction
                obj.dev = [];
                switch computer
                    case obj.supportedArchs
                        obj.preferencePropertyNames = ...
                            {'port','board','interfaceConfiguration'};
                        obj.loadSavedPreferences;
                        obj.listenForPreferenceChanges;
                        if nargin > 0 && ~isempty(port)
                            obj.port = port;
                        end
                        if nargin > 1 && ~isempty(board)
                            obj.board = board;
                        end
                        obj.openInterface;
                    otherwise
                        ME = MException(obj.archWarningID,...
                            'Unsupported Computer');
                        errorMsg = sprintf('%s: %s is an unsupported computer archtecture',...
                            class(obj),computer);
                        handleError(ME,true,...
                            errorMsg);
                end
            end            
        end
        
        
        function isOpen = openInterface(obj) % Open and initialize the interface
            % NEEDS WRITING
            if isa(obj.dev,'arduino') && obj.validateInterface
                % If the dev is already open and valid, do nothing
                isOpen = true;
            else
                % Open and validate the nidaq board
                try
                    devices = daq.getDevices;
                    s = daq.createSession('ni');
                    obj.dev = s; % this is wrong
                catch ME
                    handleError(ME,obj.useGUI,...
                        sprintf('%s Creation Error',class(obj)));
                    isOpen = false;
                    return;
                end
                isOpen = obj.validateInterface();
            end
        end
        
        
        function delete(obj)
            % NEEDS WRITING
            if obj.isConstructed
                obj.hideWarnings(false);
                if ~isempty(obj.dev) && obj.validateInterface
                    obj.closeInterface;
                end
            end
        end
        
        
        function closeInterface(obj)
            % NEEDS WRITING
            % Close the interface - whatever that means for daq
            obj.dev = [];
        end
        
        function isValid = validateInterface(obj) 
            % Verify device availibility and communication
            % NEEDS WRITING
            isValid = true;
            try
                
            catch ME
                handleError(ME,obj.useGUI,...
                    sprintf('%s Validation Error',class(obj)));
                isValid = false;
            end
        end
        
        
        % TTL Interface methods        
        
        function startRecording(obj) 
            % Send signal to start recording
            % NEEDS WRITING
        end
        
        function stopRecording(obj) 
            % Send signal to stop recording
            % NEEDS WRITING
        end
        
        function strobe(obj) 
            % Briefly activate strobe bit
            % NEEDS WRITING
        end
        
        function setEventWord(obj,value) 
            % Set event word to specified value
            % NEEDS WRITING
        end
        
        function strobeEventWord(obj,value) 
            % Set event word then strobe
            % NEEDS WRITING
        end
        
        
    end
    
end