classdef arduinoSerialPulseGenerator < singletonClass ...
        & storedPreferenceClass
    
    % Use an Arduino Uno to control laser pulses and timing
    % Serial commands used to set firmware variables
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'adruinoSerialPulseGenerator';
        configWarningID = 'adruinoSerialPulseGenerator:CONFIG';
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
    
    properties (SetAccess=private,Hidden=true)
        
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
        
        function openConnection(obj,reconnectFlag)
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
                configureCallback(obj.serialPort,"terminator",@(src,evnt)respondToData(obj));
                tic
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
                obj.sendString('VALIDATE');
                response = char(readline(obj.serialPort));
                isValid = strcmp(response(1:end-1),'VALID');
                configureCallback(obj.serialPort,"terminator",...
                    @(src,evnt)respondToData(obj));
            catch ME
                handleError(ME,true,'Validation Error');
            end
        end
        
        %         function success = turnLightOff(obj)
        %             success = true;
        %             try
        %                 obj.sendString('ABORT');
        %             catch
        %                 success = false;
        %             end
        %
        %
        %         end
        
        function closeConnection(obj)
            delete(obj.serialPort);
            obj.serialPort = [];
        end
        
        function respondToData(obj,varargin)
            dataStr = readline(obj.serialPort);
            disp(dataStr);
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
            nCh = length(string);
            if nCh >= obj.BUFFERSIZE
                error('String too long for serial buffer');
            end
            buff = blanks(obj.BUFFERSIZE);
            buff(1:nCh) = string;
            buff(nCh+1) = obj.NEWLINE;
            obj.serialPort.write(buff,"char");
        end
        
        %         function isValid = validateInterface(obj)
        %             isValid = false;
        %         end
        
    end
    
end