classdef alphaMaskClass < handle
    % Abstract class used to define alpha masks
    
    properties
        maskMatrix
    end
    
    properties (Hidden=true)
        masktex % texture index generated with Screen('MakeTexture')
        win % the window to which the texture applies
        textureNeedsRefresh
        disabled
    end
    
    properties (Access=private)
        listeners % responds to screen open, close and clear events
    end
    
    methods (Abstract)
        % Calculate the Rows x Cols x 2 matrix that defines the mask
        makeMask(obj)
        % Show the mask on the screen, for demonstration purposes
        showMask(obj)
    end
    
    methods
        
        function obj = alphaMaskClass
            sio = screenInterfaceClass.returnInterface;
            obj.listeners = addlistener(sio,'ScreenOpening',...
                @(hObj,evnt)handleScreenEvent(obj,'open'));
            obj.listeners(2) = addlistener(sio,'ScreenClosing',...
                @(hObj,evnt)handleScreenEvent(obj,'close'));
            obj.listeners(3) = addlistener(sio,'TexturesCleared',...
                @(hObj,evnt)handleScreenEvent(obj,'cleared'));
            obj.textureNeedsRefresh = false;
            obj.disabled = false;
        end
        
        function delete(obj)
            delete(obj.listeners);
        end
        
        function set.maskMatrix(obj,matrix)
            [~,~,layers] = size(matrix);
            if layers ~= 2
                error('alphaMaskClass.maskMatrix must be a rows x cols x 2 matrix');
            end
            obj.maskMatrix = matrix;
            obj.textureNeedsRefresh = true; %#ok<MCSUP>
        end
        
        function ti = makeTexture(obj)
            % Make a texture using the maskMatrix, get the current window
            % info from the screenInterfaceClass
            %fprintf('%s.makeTexture masktex = %i, win = %i\n',class(obj),obj.masktex,obj.win);
            if obj.disabled
                ti = 0;
            else
                sio = screenInterfaceClass.returnInterface;
                if isempty(obj.win) || obj.win ~= sio.getWindow;
                    obj.win = sio.getWindow;
                end
                if isempty(obj.win)
                    obj.masktex = [];
                else
                    try
                        obj.masktex=Screen('MakeTexture', obj.win,obj.maskMatrix);
                        obj.textureNeedsRefresh = false;
                    catch ME
                        handleWarning(ME,true,'%s.makeTexture failed',class(obj));
                        obj.masktex = 0;
                    end
                end
                ti = obj.masktex;
            end
        end
        
        function disableMask(obj)
            obj.disabled = true;
            obj.masktex = [];
        end
        
        function enableMask(obj)
            obj.disabled = false;
            obj.makeTexture;
        end
        
        function trueOrFalse = isEnabled(obj)
            trueOrFalse = ~obj.disabled;
        end
        
        function ti = getTexture(obj)
            if obj.textureNeedsRefresh && ~isempty(obj.win)
                obj.makeTexture;
            end
            ti = obj.ti;
        end
                
        function renderMask(obj)
            % Overload this method for more advanced rending options (i.e.
            % rectangle specification, rotation, etc.)
            %fprintf('%s.renderMask masktex = %i, win = %i\n',class(obj),obj.masktex,obj.win);            
            if obj.win && obj.masktex && ~obj.disabled
                if obj.textureNeedsRefresh
                    obj.makeTexture;
                end
                Screen('DrawTexture',obj.win,obj.masktex);
            end
        end
        
        function renderPattern(obj)
            % Draw a checkerboard pattern to the screen - useful for 
            % configuring masks
            sio = screenInterfaceClass.returnInterface;
            if isempty(obj.win) || obj.win ~= sio.getWindow;
                obj.win = sio.getWindow;
            end
            if isempty(obj.win)
                return;
            end
            res = sio.getScreenResolution;
            width = res.width;
            height = res.height;
            sidelength = 20; %pixels
            numCheckers =  ceil([width; height] ./ sidelength);
            miniboard = eye(2,'uint8') .* 255;
            checkerboard = repmat(miniboard, ceil(0.5 .* numCheckers)')';
            checkerboard = imresize(checkerboard,sidelength,'box'); % scale up
            checkerboard = checkerboard(1:height,1:width); % clip if needed
            texture = Screen('MakeTexture', obj.win, checkerboard);
            Screen('DrawTexture',obj.win,texture);
            Screen('close',texture);
        end
        
    end
    
    methods (Access=private)
        
        function handleScreenEvent(obj,eventType)
            switch eventType
                case 'open'
                    obj.makeTexture;
                case 'close'
                    obj.masktex = [];
                    obj.win = [];
                case 'cleared'
                    obj.makeTexture;
            end
        end
        
    end
    
end