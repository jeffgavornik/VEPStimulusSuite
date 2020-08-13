classdef arduinoClass < singletonClass ...
        & ttlHardwareAbstractClass ...
        & daqHardwareAbstractClass ...
        & storedPreferenceClass ...
        & classThatThrowsWarnings
    
    % Notes: need to install support package for this to work
    % On linux, need to create a synmolic link to the arduino serial port.
    % i.e. sudo ln -s /dev/ttyACM0 /dev/ttyS100
    %
    % Auduino USB communication is slow due to the USB chip set.
    % Approximately 20 ms round trip for one serial command.  This means
    % that a stobe takes about 40 ms
    %
    % https://www.mathworks.com/help/supportpkg/arduinoio/ug/find-arduino-port-on-windows-mac-and-linux.html
    
    % TTL interface defines start, stop and strobe bits as well as an 8-bit
    % data word
    
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'arduinoClass';
        configErrorID = 'arduinoClass:CONFIG';
        archWarningID = 'arduinoClass:ARCH';
        statusWarningID = 'arduinoClass:badStatus';
    end
    
    properties (SetObservable,AbortSet)
        port
        board
        interfaceConfiguration % either TTL or DAQ
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
        % Define control signal locations
        TTLSTARTPIN = 'D2';
        TTLSTROBEPIN = 'D3';
        % Define DIO bits for event word
        TTLEVNTPINS = {'D4' 'D5' 'D6' 'D7' 'D8' 'D9' 'D10' 'D11'};
        OPENDIOPINS = {'D13' 'D14'};
    end
    
    methods
        
        function obj = arduinoClass(port,board)
            % Open the arduino interface - dev property will be
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
        
        function delete(obj)
            if obj.isConstructed
                obj.hideWarnings(false);
                if ~isempty(obj.dev) && obj.validateInterface
                    obj.closeInterface;
                end
            end
        end
        
        function isOpen = openInterface(obj) % Open and initialize the interface
            if isa(obj.dev,'arduino') && obj.validateInterface
                % If the dev is already open and valid, do nothing
                isOpen = true;
            else
                % Open and validate the dev
                try
                    obj.dev = arduino(obj.port,obj.board);
                catch ME
                    handleError(ME,obj.useGUI,'Arduino Creation Error');
                    isOpen = false;
                    return;
                end
                %obj.dev = arduino('/dev/ttyS100','uno');
                isOpen = obj.validateInterface();
            end
        end
        
        function closeInterface(obj)
            % Close the interface - delete is user protected for arduino so
            % this is the best we can do
            obj.dev = [];
        end
        
        function isValid = validateInterface(obj) % Verify device availibility and communication
            isValid = true;
            try
                pins = obj.dev.AvailablePins;
                origMode = obj.dev.configurePin(pins{1});
                obj.dev.configurePin(pins{1},'Unset');
                obj.dev.configurePin(pins{1},origMode);
            catch ME
                handleError(ME,obj.useGUI,'Arduino Validation Error');
                isValid = false;
            end
        end
        
        function set.interfaceConfiguration(obj,config)
            switch lower(config)
                case 'ttl'
                    obj.interfaceConfiguration = 'TTL';
                case 'daq'
                    obj.interfaceConfiguration = 'DAQ';
                otherwise
                    ME = MException(obj.configErrorID,...
                            'Bad Configuration');
                        handleError(ME,true,...
                            sprintf('%s: %s is an unsupported configuration (DAQ or TTL only)',class(obj),config));
            end
        end
        
        % TTL Interface methods        
        
        function startRecording(obj) % Send signal to start recording
            writeDigitalPin(obj.dev,obj.TTLSTARTPIN, 1);
        end
        
        function stopRecording(obj) % Send signal to stop recording
            writeDigitalPin(obj.dev,obj.TTLSTARTPIN, 0);
        end
        
        function strobe(obj) % Briefly activate strobe bit
            writeDigitalPin(obj.dev,obj.TTLSTROBEPIN, 1);
            writeDigitalPin(obj.dev,obj.TTLSTROBEPIN, 0);
        end
        
        function setEventWord(obj,value) % Set event word to specified value
            
        end
        
        function strobeEventWord(obj,value) % Set event word then strobe
            
        end
        
        % DAQ Interface methods
        
        function success = writeAnalog(obj,varargin)            
            ME = MException(obj.analogOutWarningID,...
                'No true analog output');
            handleWarning(ME,obj.useGUI,'PWM based analog output only');
            
        end
        
        function data = readAnalog(obj,varargin)
            data = [];
        end
        
        function success = writeDigital(obj,varargin)
            success = false;
        end
        
        function data = readDigital(obj,varargin)
            data = [];
        end
        
        function testCommandLatency(obj,trials)
            t1 = GetSecs;
            for ii = 1:trials
                %origMode = obj.dev.configurePin('D2'); %#ok<NASGU>
                writeDigitalPin(obj.dev,obj.TTLSTARTPIN, 0);
            end
            t2 = GetSecs;
            fprintf('Average command latency over %i trials is %1.4f s\n',...
                trials,(t2-t1)/trials);
        end
        
        
        
    end
    
end