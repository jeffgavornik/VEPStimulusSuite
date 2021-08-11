classdef arduinoSerialPulseGenerator < singletonClass ...
        & storedPreferenceClass
    
    % Use an Arduino Uno to control laser pulses and timing
    % Serial commands used to set firmware variables
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'adruinoSerialPulseGenerator';
        configWarningID = 'adruinoSerialPulseGenerator:CONFIG';
        triggerCmd = 'TRIGGER';
        validateCmd = 'VALIDATE';
        abortCmd = 'ABORT';
    end
    
    properties
        burstDuration
        pulseFreq
        minInterCmdTime = 0.010;
    end
    
    properties (SetObservable,AbortSet)
        BAUDRATE % 115200
        SerialPortNameStr
    end
    
    properties (Constant)
        BUFFERSIZE = 52;
        NEWLINE = 10;
    end
    
    properties
        serialPort % the usb-connected Arduino
    end
    
    properties (Access=private)
        
        lastWriteCmdTime = 0;
        evntTime
    end
    
    
    methods
        
        function obj = arduinoSerialPulseGenerator()
            if obj.singletonNeedsConstruction
                obj.preferencePropertyNames = {'BAUDRATE','SerialPortNameStr'};
                obj.loadSavedPreferences;
                obj.listenForPreferenceChanges;
                obj.findArduino();
            end
        end
        
        function success = openConnection(obj,reconnectFlag)
            % use current obj settings to connect to the arduino
            if nargin < 2
                reconnectFlag = false;
            end
            try
                if isempty(obj.SerialPortNameStr) || isempty(obj.BAUDRATE)
                    error('SerialPortNameStr or BAUDRATE unspecified');
                end
                if reconnectFlag
                    delete(obj.serialPort);
                end
                obj.serialPort = serialport(obj.SerialPortNameStr,obj.BAUDRATE);
                %configureCallback(obj.serialPort,"byte",52,@(src,evnt)respondToData(obj));
                configureCallback(obj.serialPort,...
                    "terminator",@(src,evnt)respondToData(obj));
                success = true;
            catch ME
                handleError(ME,true,'Arduino Connection Error');
                success = false;
            end
        end
        
        function isValid = validateInterface(obj)
            isValid = false;
            if isempty(obj.serialPort)
                return;
            end
            try
                configureCallback(obj.serialPort,"off");
                obj.sendString(obj.validateCmd);
                response = char(readline(obj.serialPort));
                isValid = strcmp(response(1:end-1),'VALID');
                configureCallback(obj.serialPort,"terminator",...
                    @(src,evnt)respondToData(obj));
                if ~isValid
                    fprintf('Failed validation String:%s\n',...
                        response(1:end-1));
                end
            catch ME
                handleError(ME,true,'Validation Error');
            end
        end
        
        function closeConnection(obj)
            delete(obj.serialPort);
            obj.serialPort = [];
        end
        
        function respondToData(obj,varargin)
            dataStr = readline(obj.serialPort); %#ok<NASGU>
            %             switch dataStr.strip
            %                 case 'BurstStarting'
            %                     fprintf('Burst Start\n');
            %                     obj.evntTime = GetSecs;
            %                 case {'BurstComplete','BurstAborted'}
            %                     duration = GetSecs-obj.evntTime;
            %                     fprintf('Burst Complete, duration = %1.3f sec\n',duration);
            %                 otherwise
            %                     fprintf('Serial Data Received:%s\n',dataStr);
            %             end
        end
        
        function set.burstDuration(obj,value)
            obj.burstDuration = value;
            % obj.sendString(sprintf('%i:-1',value));
            obj.sendString(sprintf('burstDuration:%i',value));
        end
        
        function set.pulseFreq(obj,value)
            obj.pulseFreq = value;
            % obj.sendString(sprintf('-1:%i',value));
            obj.sendString(sprintf('pulseFreq:%1.2f',value));
        end
        
        function triggerPulse(obj)
            obj.sendString(obj.triggerCmd);
        end
        
        function abortPulse(obj)
            obj.sendString(obj.abortCmd);
        end
        
        function findArduino(obj,forceflag)
            % Let the user select which port to use for the arduino
            if nargin < 2
                forceflag = false;
            end
            if isempty(obj.SerialPortNameStr) || forceflag
                % Let user select the correct port
                ports = serialportlist("available");
                indx = listdlg('ListString',ports,...
                    'SelectionMode','single','PromptString',...
                    'Select Arduino Uno');
                obj.SerialPortNameStr = ports(indx);
            end
            obj.openConnection();
        end
        
        function sendString(obj,string)
            buff = sprint('<%s>',string);
            obj.serialPort.write(buff,"char");
            
            %             % Make sure commands don't get sent too fast - this can cause
            %             % problems with the code that parses command strings
            %             currTime = GetSecs;
            %             while (currTime-obj.lastWriteCmdTime<obj.minInterCmdTime)
            %                 currTime = GetSecs;
            %             end
            %             obj.lastWriteCmdTime = currTime;
            %             % Create and fill buffer then send
            %             nCh = length(string);
            %             if nCh >= obj.BUFFERSIZE
            %                 error('String too long for serial buffer');
            %             end
            %             buff = blanks(obj.BUFFERSIZE);
            %             buff(1:nCh) = string;
            %             buff(nCh+1) = obj.NEWLINE;
            %             obj.serialPort.write(buff,"char");
            %             %fprintf('SendStr:<%s>\n',buff);
        end
        
        
    end
    
end