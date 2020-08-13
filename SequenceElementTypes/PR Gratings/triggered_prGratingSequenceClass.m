classdef triggered_prGratingSequenceClass < prGratingSequenceClass
    % Modified PR sequence that does not start drawing until the ttl 
    events
        WaitingForTrigger
    end
    
    properties (Access=private)
        triggerListener
    end
    
    methods
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
        
        
    end
end