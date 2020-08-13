classdef optoStimUSB1208FSPlusHWInterface < singletonClass ...
        & optoStimHWInterfaceAbstractClass ...
        & storedPreferenceClass
    
    % Use the USB1208FSPlus to control optogenetic stimulation
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'optoStimUSB1208FSPlusHWInterface';
        configWarningID = 'optoStimHWInterface:CONFIG';
    end
    
    properties (SetObservable,AbortSet)
        % See USB1208FS pinout for hardware details
        AIChannel % 0-7
        AIChannelMode % Either SE or DIFF
        DOPORT % 0 for A, 1 for B
        DOBIT % 0-7
    end
    
    properties
        hwObject % the usb device
        config
    end
    
    properties (SetAccess=private,Hidden=true)
         % Support threaded laser pulses
        pThread = [];
        pThreadInfo = [];
    end
    
    methods

        function obj = optoStimUSB1208FSPlusHWInterface(config)
            if obj.singletonNeedsConstruction
                obj.preferencePropertyNames = { ...
                    'AIChannel','AIChannelMode',...
                    'DOPORT','DOBIT'};
                obj.hwObject = usb1208FSPlusClass;
                obj.loadSavedPreferences;
                obj.listenForPreferenceChanges;
                if nargin == 0
                    config = 'digital';
                end
                obj.config = config;
            end
        end
        
        % Instantiate abstract methods
        function isOpen = openInterface(obj)
            isOpen = false;
            if isempty(obj.hwObject) || ~isvalid(obj.hwObject)
                obj.hwObject = usb1208FSPlusClass;
                isOpen = obj.hwObject.validateInterface();
            end
        end
        
        function closeInterface(obj) %#ok<MANU>
            % We don't want to acidentally delete a device that is being
            % used for something else (TTL pulses, etc.) so don't do
            % anything and let someone else worry about it
        end
        
        function isValid = validateInterface(obj)
            isValid = false;
            if isa(obj.hwObject,'usb1208FSPlusClass')
                isValid = obj.hwObject.validateInterface();
            end
        end
        
        % Control commands
        
        function status = turnLightOn(obj)
            status = obj.setLightLevel(1);
        end
        
        function status = turnLightOff(obj)
            status = obj.setLightLevel(0);
        end
        
        function status = setLightLevel(obj,value)
            switch obj.config
                case 'DIGITAL'
                    status = obj.hwObject.writeDigital(...
                        obj.DOPORT,obj.DOBIT,value);
                case 'ANALOG'
                    status = obj.hwObject.writeAnalog(...
                        obj.AIChannel,value);
            end
        end
        
        function startPulseTrain(obj,pulseWidth,pulseTrainDuration)
            if nargin < 3
                error('Three inputs required');
            end
            if ~isempty(obj.pThread)
                [~,~,~,~,isComplete] = getThreadInfo(obj.pThreadInfo,0);
                if ~isComplete
                    error('Old thread still active');
                else
                    % This is the case where a previous pulse train
                    % finished but stopPulseTrain has not been called
                    getThreadInfo(obj.pThreadInfo,1);
                    obj.pThread = [];
                    obj.pThreadInfo = [];
                end
            end
            nPulses = pulseTrainDuration/(2*pulseWidth);
            [obj.pThread,obj.pThreadInfo] = pulseLaserThreaded(...
                obj.hwObject.dev,pulseWidth,nPulses);
        end
        
        function stopPulseTrain(obj)
            [~,~,~,~,isComplete] = getThreadInfo(obj.pThreadInfo,0);
            if ~isComplete
                cancelThread(obj.pThread);
                getThreadInfo(obj.pThreadInfo,1); % release memory
            end
            obj.pThread = [];
            obj.pThreadInfo = [];
        end
        
        % Property setters
        function set.config(obj,config)
            % Show current configuration to the user and confirm it is
            % correct
            try 
                if sum(strcmpi({'analog','digital'},config))
                    msg = sprintf('Optical stimulus is configuring for %s control',upper(config));
                    switch upper(config)
                        case 'DIGITAL'
                            msg = sprintf('%s\nDOPORT=%i,BIT=%i',msg,...
                                obj.DOPORT,obj.DOBIT); %#ok<MCSUP>
                        case 'ANALOG'
                            msg = sprintf('%s\nAIChannel=%i,Mode=%i',...
                                msg,obj.AIChannel,obj.AIChannelMode); %#ok<MCSUP>
                    end
                    msg = {msg;'Please verify that this is correct'};
                    if strcmp(questdlg(msg, ...
                            'USB1208FSPlus OptoStim Configuration','Correct', 'Incorrect','Correct'),...
                            'Incorrect')
                        error(obj.configWarningID,'Check HW Configuration');
                    end
                    obj.config = upper(config);
                else
                    error(obj.configWarningID,'Invalid Device Config');
                end
            catch ME
                handleError(ME,true,'Invalid Configuration');
            end
        end
        
        function set.AIChannel(obj,channel)
            try
                if sum(channel == usb1208FSPlusClass.AOCHANNELS)
                    obj.AIChannel = channel;
                else
                    error(obj.configWarningID,'Invalid AI Channel');
                end
            catch ME
                handleError(ME,true,'Invalid Configuration');
            end
        end
            
        function set.AIChannelMode(obj,mode)
            try
                obj.hwObject.AIChannelMode = upper(mode); %#ok<MCSUP>
                obj.AIChannelMode = upper(mode);
            catch ME
                handleError(ME,true,'Invalid Configuration');
            end
        end
            
        function set.DOPORT(obj,port)
            try
                if sum(port == [0 1])
                    obj.DOPORT = port;
                else
                    error(obj.configWarningID,'Invalid Digital port');
                end
            catch ME
                handleError(ME,true,'Invalid Configuration');
            end
        end
        
        function set.DOBIT(obj,bit)
            try
                if sum(bit == [0 1 2 3 4 5 6 7])
                    obj.DOBIT = bit;
                else
                    error(obj.configWarningID,'Invalid Digital bit');
                end
            catch ME
                handleError(ME,true,'Invalid Configuration');
            end
        end

        
       
        
    end
    
end