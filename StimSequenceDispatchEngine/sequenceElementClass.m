classdef sequenceElementClass < handle
    
    properties
        ID
        resourceDict
        resourceKey
        rotation
        holdTime
        flipFnc % optional function handle to be executed at flip time
        eventValue
    end
    
    properties (Hidden=true)
        ttlInterface
        scaSupport
        printFcn
    end
    
    properties (Hidden=true)
        % If this is set to true, hold times will be adjusted to match up
        % with screen refresh time
        alignWithScreenRefreshRate
    end
    
    methods
        
        function obj = sequenceElementClass()
            %fprintf('creating class %s\n',class(obj));
            obj.ID = '';
            obj.rotation = 0;
            obj.resourceKey = '';
            obj.eventValue = 0;
            obj.ttlInterface = ttlInterfaceClass.getTTLInterface;
            obj.printFcn = @fprintf;
            obj.scaSupport = false;
            obj.flipFnc = []; % function handle to execute at flip time
            obj.alignWithScreenRefreshRate = true;
        end
        
        function provideSCASupport(obj)
            % Interface with the ScrnCtrlApp
            if ~ obj.scaSupport
                obj.scaSupport = true;
                % obj.ttlInterface = ttlInterfaceClass.findHardwareInterface;
                obj.printFcn = @scaPrintf;
            end
        end
        
        function issueDrawCommands(obj,targetWindow)
            % Override this funciton to change drawing behavior
            % If there is no resource key, the element will result in a
            % gray
            try
                %fprintf('%s:issueDrawCommands\n',class(obj));
                if ~isempty(obj.resourceKey)
                    textures = obj.resourceDict(obj.resourceKey);
                    for iT = 1:length(textures)
                        Screen('DrawTexture',targetWindow,...
                            textures(iT),[],[],obj.rotation);
                    end
                end
                setEventWord(obj.ttlInterface,obj.eventValue);
            catch ME
                obj.printFcn('%s.issueDrawCommands Error:\n%s\n',class(obj),...
                    getReport(ME));
            end
        end
        
        function holdTime = getHoldTime(obj)
            holdTime = obj.holdTime;
        end
        
        function setFlipFnc(obj,fncHandle)
           obj.flipFnc = fncHandle; 
        end
        
        function descStr = tellElementDetails(obj)
            descStr = sprintf('ID:%s,EvntValue:%i,HoldTime:%1.3f',...
                obj.ID,obj.eventValue,round(obj.holdTime,3));
            descStr = sprintf('%s,Rotation:%1.2f,ResourceKey:%s',...
                descStr,obj.rotation,obj.resourceKey);
            if isa(obj.flipFnc,'function_handle')
                flipStr = func2str(obj.flipFnc);
            else
                flipStr = '';
            end
            descStr = sprintf('%s,FlipFcn:%s',...
                descStr,flipStr);
        end
        
        function alignTiming(obj)
            try
                % Sets the hold time to be an integer of the screen refresh
                % rate
                if obj.alignWithScreenRefreshRate
                    sio = screenInterfaceClass.returnInterface;
                    [~,ifi] = sio.getMonitorRefreshRate;
                    if isempty(ifi)
                        error('%s.alignTiming: ifi is empty',class(obj));
                    end
                    remainder = rem(obj.holdTime,ifi);
                    if remainder ~= 0
                        obj.holdTime = obj.holdTime + ifi - remainder;
                    end
                end
            catch ME
                handleError(ME,false,'timing alignment failure');
            end
        end
        
        function renderedImage = getRenderedImage(obj)
            % Will try to return the matrix that is being rendered by the
            % sequence element using Screen('GetImage')
            try
                sio = screenInterfaceClass.returnInterface;
                obj.issueDrawCommands(sio.window);
                sio.flipScreen;
                imageMatrix=Screen('GetImage',sio.window);
            catch ME
                handleError(ME,true,'Rendering Problem');
                imageMatrix = [];
            end
            renderedImage.imageMatrix = imageMatrix;
            renderedImage.holdTime = obj.holdTime;
            renderedImage.ID = obj.ID;
            renderedImage.eventValue = obj.eventValue;
        end
        
    end
    
end
        
        
        