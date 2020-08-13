classdef prGratingSequenceClass < abstractSequenceClass ...
        & screenAlignedTimeClass
   
    properties (SetObservable)
        % Grating parameters
        rotation = 0 % degrees counter-clockwise from 0 (horizontal)
        spatialFrequency = 0.05; % cycles per degree
        contrast = 100; % 0 to 100 percent
        nPhaseReversals % number of phase reversals per presentation cycle
        
        % These will be automatically synched to each other so necessary to
        % define only the flip period or frequency of phase reversal
        flipPeriod = 0.5; % seconds
        flipFrequency % Hz
        
        % If scalar, same event value will be used for the flip and flop
        eventValues = [];
    end
    
    properties (Access=protected)
        ffCount
        textures = [];
        sio % screenInterfaceClass object
        sdeo % sequence dispatch engine
        ttl % ttl interface
    end
    
    events
        timeParamChanged
    end
    
    methods
        
        function obj = prGratingSequenceClass()
            obj.timeVariablesNeedingAlignment = 'flipPeriod';
            addlistener(obj,'spatialFrequency','PostSet',...
                @(src,evnt)createTextures(obj));
            addlistener(obj,'contrast','PostSet',...
                @(src,evnt)createTextures(obj));
            addlistener(obj,'flipPeriod','PostSet',...
                @(src,evnt)synchTimeParams(obj,'freq'));
            addlistener(obj,'flipFrequency','PostSet',...
                @(src,evnt)synchTimeParams(obj,'period'));
            obj.sio = screenInterfaceClass.returnInterface;
            obj.sdeo = sequenceDispatchEngineClass.getEngine;
            obj.ttl = ttlInterfaceClass.getTTLInterface;
        end
        
        function set.rotation(obj,angle)
            obj.rotation = convert_cw2ccw(angle); % PTB expects CW rotations
        end
        
        function set.spatialFrequency(obj,spatialFrequency)
            spatialFrequency = max([0.01 spatialFrequency]);
            obj.spatialFrequency = spatialFrequency;
        end
        
        function set.contrast(obj,contrast)
            contrast = max([0 contrast]);
            contrast = min([100 contrast]);
            obj.contrast = contrast;
        end
        
        function set.eventValues(obj,eventValues)
            obj.eventValues = eventValues;
        end

        function startSequence(obj)
            if isempty(obj.eventValues)
                error('event values have not been set');
            end
            obj.sio.openScreen;
            obj.targetWindow = obj.sio.window;
            obj.printFcn('Sequence ''%s'' at %s\n',...
                    obj.sequenceName,datestr(now,13));
            if isempty(obj.textures)
                obj.createTextures;
            end
            notify(obj,'SequenceStarted');
            obj.ffCount = 1;
            Screen('DrawTexture',obj.targetWindow,...
                obj.textures(1),[],[],obj.rotation);
            obj.sdeo.flipNow([]);
        end
        
        function stopSequence(obj)
            notify(obj,'LastElement',...
                notificationEventClass('stopSequence'));
        end
        
        function prepNextElement(obj)
            obj.ffCount = obj.ffCount + 1;
            
            if obj.ffCount <= obj.nPhaseReversals*2
                if mod(obj.ffCount,2)
                    iTxt = 1;
                else
                    iTxt = 2;
                end
                Screen('DrawTexture',obj.targetWindow,...
                    obj.textures(iTxt),[],[],obj.rotation);
                if length(obj.eventValues) == 1
                    obj.ttl.setEventWord(obj.eventValues);
                else
                    obj.ttl.setEventWord(obj.eventValues(iTxt));
                end
                obj.sdeo.scheduleFlipRelativeToVBL(obj.flipPeriod,[]);
            else
                obj.sdeo.scheduleFlipRelativeToVBL(obj.flipPeriod,[]);
                notify(obj,'LastElement');
            end
        end
                
        % Return an estimate (in seconds) of how long it will take to run
        % the sequence
        function reqTime = calculateSequenceTime(obj)
            reqTime = obj.flipPeriod * obj.nPhaseReversals * 2;
        end
        
        % Return a string that describes the stimulus
        function descStrs = tellSequenceDetails(obj)
            descStrs{1} = sprintf('PR Sequence:''%s'':',obj.sequenceName);
            paramStr = sprintf('%1.3f cyc/%s %1.1f%%',...
                obj.spatialFrequency,char(176),obj.contrast);
            if length(obj.eventValues) == 1
                descStrs{2} = sprintf('ID:Flip/Flop %s,EvntValue:%i,HoldTime:%1.3f,Rotation:%1.2f',...
                paramStr,obj.eventValues,obj.flipPeriod,obj.rotation);
            else
                descStrs{2} = sprintf('ID:Flip %s,EvntValue:%i,HoldTime:%1.3f,Rotation:%1.2f',...
                    paramStr,obj.eventValues(1),obj.flipPeriod,obj.rotation);
                descStrs{3} = sprintf('ID:Flop %s,EvntValue:%i,HoldTime:%1.3f,Rotation:%1.2f',...
                paramStr,obj.eventValues(2),obj.flipPeriod,obj.rotation);
            end
        end
        
    end
    
    methods (Access=private)
        
        function createTextures(obj)
            if ~isempty(obj.textures)
                Screen('close',obj.textures);
            end
            [flip,flop] = make_PR_gratings(obj.spatialFrequency,...
                obj.contrast);
            obj.textures(1) = obj.sio.makeTexture(flip);
            obj.textures(2) = obj.sio.makeTexture(flop);
        end
        
        function synchTimeParams(obj,needsUpdate)
            % event.proplistener.Recursive=0 so no infinite loop
            switch needsUpdate
                case 'period'
                    obj.flipPeriod = 1/obj.flipFrequency;
                case 'freq'
                    obj.flipFrequency = 1/obj.flipPeriod;
            end
        end
        
    end
    
end