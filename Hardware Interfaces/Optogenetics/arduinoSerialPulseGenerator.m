classdef arduinoSerialPulseGenerator < singletonClass ...
        & storedPreferenceClass
    
    % Use an Arduino Uno to control laser pulses and timing
    % Serial commands used to set firmware variables
    %
    % Should have some way to sync params with the arduino on connection
    %
    % note: testSerialLatency shows that a single command sent via the
    % serial interface has a latency of about 0.76 ms on standard linux
    % build
    
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
        % Arduino initilizes to use 100% duty cycle, set this param to
        % change it
        dutyCycle
        showReceivedSerialData = false;
        dataRecvdCallbackEnabled
        burstActive
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
        
        function delete(obj)
            obj.closeConnection;
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
                obj.setDataCallback('on');
                success = true;
            catch ME
                handleError(ME,true,'Arduino Connection Error');
                success = false;
            end
        end
        
        function setDataCallback(obj,onOrOff)
            switch onOrOff
                case 'on'
                    %configureCallback(obj.serialPort,"byte",52,@(src,evnt)respondToData(obj));
                    configureCallback(obj.serialPort,"terminator",...
                        @(src,evnt)respondToData(obj));
                    obj.dataRecvdCallbackEnabled = true;
                case 'off'
                    configureCallback(obj.serialPort,"off");
                    obj.dataRecvdCallbackEnabled = false;
                otherwise
                    error('onOrOff must be either on or off');
            end
        end
        
        function isValid = validateInterface(obj)
            isValid = false;
            if isempty(obj.serialPort)
                return;
            end
            try
                obj.setDataCallback('off');
                obj.sendString(obj.validateCmd);
                response = char(readline(obj.serialPort));
                isValid = strcmp(response(1:end-1),'VALID');
                if ~isValid
                    fprintf(2,'%s.validateInterface: Failed validation String:%s\n',...
                        class(obj),response(1:end-1));
                end
            catch ME
                handleError(ME,true,'Validation Error');
            end
            obj.setDataCallback('on');
        end
        
        function closeConnection(obj)
            delete(obj.serialPort);
            obj.serialPort = [];
        end
        
        function respondToData(obj,varargin)
            dataStr = readline(obj.serialPort);
            switch dataStr.strip
                case 'BurstStarting'
                    obj.burstActive = true;
                case {'BurstComplete','BurstAborted'}
                    obj.burstActive = false;
            end
            if obj.showReceivedSerialData
                switch dataStr.strip
                    case 'BurstStarting'
                        fprintf('Burst Start\n');
                        obj.evntTime = GetSecs;
                    case 'BurstComplete'
                        duration = GetSecs-obj.evntTime;
                        fprintf('Burst Complete, duration = %1.3f sec\n',duration);
                    case 'BurstAborted'
                        duration = GetSecs-obj.evntTime;
                        fprintf('Burst Aborted, duration = %1.3f sec\n',duration);
                    otherwise
                        fprintf('Serial Data Received:%s\n',dataStr);
                end
                drawnow
            end
        end
        
        function set.burstDuration(obj,value)
            obj.burstDuration = value;
            obj.sendString(sprintf('burstDuration:%i',value));
        end
        
        function set.pulseFreq(obj,value)
            obj.pulseFreq = value;
            obj.sendString(sprintf('pulseFreq:%1.2f',value));
        end
        
        function set.dutyCycle(obj,value)
            if value < 1
                value = value * 100;
            end
            obj.dutyCycle = value;
            obj.sendString(sprintf('dutyCycle:%.0f',value));
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
            buff = sprintf('<%s>',string);
            obj.serialPort.write(buff,"char");
        end
        
        
    end
    
end