classdef ttlHardwareAbstractClass < handle
    % Define the methods that all TTL interfaces must support in order to
    % be compliant with the StimulusSuite environment.  See
    % ttlInterfaceClass for more details.
    
    events
        InterfaceOpened
        InterfaceClosed
        TTLMetadataStateToggled
    end
    
    properties (Constant,Hidden=true)
        strobeTime = 0.005; % default pulse width of 5 ms
        % Define the event code values that will be used to deliniate ASCII
        % values sent to the TTL interface in the sendStringAsEvent method
        ASCII_SEQ_DELIN = [0.2 0.6 0.4 0.8 1]
        % Define the wait time after sending each character to the TTL.
        % The appropriate value of the parameter depends on what is being
        % done with the data and how it is being generated.  The value needs
        % to be slow enough that everything gets through.
        ASCII_WAIT_TIME = 1e-2;
    end
    
    properties
        TTLMetaDataEnabled = false;
    end
    
    methods (Abstract)
        
        isOpen = openInterface(obj) % Open and initialize the interface
        
        closeInterface(obj) % Close the interface
        
        isValid = validateInterface(obj) % Verify device availibility and communication
        
        startRecording(obj) % Send signal to start recording
        
        stopRecording(obj) % Send signal to stop recording
        
        strobe(obj,varargin) % Briefly activate strobe bit
        
        setEventWord(obj,value,varargin) % Set event word to specified value
        
        strobeEventWord(obj,value,varargin) % Set event word then strobe
        
        % The following are useful for calibration, etc.
        [minValue,maxValue] = getEventRange(obj)
    end
    
    methods
        
        function value = get.TTLMetaDataEnabled(obj)
            %if isempty(obj.TTLMetaDataEnabled)
            %    obj.TTLMetaDataEnabled = true;
            %end
            value = obj.TTLMetaDataEnabled;
        end
        
        function set.TTLMetaDataEnabled(obj,value)
            obj.TTLMetaDataEnabled = value;
            notify(obj,'TTLMetadataStateToggled');
        end
        
        function asciiVals = sendStringAsEvent(obj,string)
            % This methods will convert a string to an array of ascii
            % values and send them to the TTL system as event words.  The
            % ASCII string is delineated by a (hopefully unique) string of
            % values based on round(obj.ASCII_SEQ_DELIN * max) where max is
            % the max value reported by obj.getEventRange.  The code is
            % reported by obj.reportDelineatorCode
            if obj.TTLMetaDataEnabled
                try
                    count = 0;
                    if ~isa(string,'cell')
                        string = {string};
                    end
                    string = [string{:}];
                    asciiVals = double(string);
                    [minValue,maxValue] = obj.getEventRange;
                    % send a sequence to identify that an ascii string follows
                    for ii = 1:length(obj.ASCII_SEQ_DELIN)
                        obj.strobeEventWord(round(maxValue*obj.ASCII_SEQ_DELIN(ii)));
                        WaitSecs(obj.ASCII_WAIT_TIME);
                        count = count + 1;
                    end
                    % send each character of the string as it's ascii value
                    nC = length(string);
                    for iC = 1:nC
                        obj.strobeEventWord(asciiVals(iC));
                        WaitSecs(obj.ASCII_WAIT_TIME);
                        count = count + 1;
                    end
                    % send a sequence to identify that an ascii string is complete
                    for ii = 1:length(obj.ASCII_SEQ_DELIN)
                        obj.strobeEventWord(round(maxValue*obj.ASCII_SEQ_DELIN(ii)));
                        WaitSecs(obj.ASCII_WAIT_TIME);
                        count = count + 1;
                    end
                    obj.setEventWord(minValue);
                    fprintf('%i event words sent to TTL\n',count);
                catch ME
                    handleError(ME,true,'Event ASCII failure');
                    asciiVals = '';
                end
            else
                ME = MException('ttlHardwareAbstractClass:stateMismatch',...
                    'TTL Metadata Logging Disabled');
                ws = sprintf(...
                    '%s.sendStringAsEvent - TTL Metadata logging disabled, string not sent',...
                    class(obj));
                handleWarning(ME,false,ws);                
            end
        end
        
        function delinCode = reportDelineatorCode(obj)
            % Return the code that will be used to delinate ascii strings
            % produced by sendStringAsEvent
            [~,maxValue] = obj.getEventRange;
            delinCode = zeros(size(obj.ASCII_SEQ_DELIN));
            for ii = 1:length(obj.ASCII_SEQ_DELIN)
                delinCode(ii) = round(maxValue*obj.ASCII_SEQ_DELIN(ii));
            end
        end
        
    end
    
end