classdef driftGratingSequenceClass < abstractSequenceClass
    
    % Render a drifting grating
    
    properties
        %nTextures
        %textures;
        textures
        holdTime
        sio

        %  nPix
        %  pixelvec
        
        nSteps = 10;
        
        phaseSteps
        phaseIndex
        phaseValues
        freq
        angle
        
        count
        countTarget = 30;
        
        gratingtex
    end
    
    methods
        
        function obj = driftGratingSequenceClass(sequenceName)
            try
                % Make sure the GLSL shading language is supported:
                AssertGLSL;
                if nargin == 1
                    obj.sequenceName = sequenceName;
                end
                obj.sio = screenInterfaceClass.returnInterface;
                obj.sio.openScreen;
                [~,obj.holdTime] = obj.sio.getMonitorRefreshRate(false);                
                obj.targetWindow = obj.sio.window;
                obj.makeTextures();
            catch ME
                handleError(ME,true,obj.configFailErrorID,[],true);
            end
        end
        
        function startSequence(obj)
            % Create a texture for each of the gratings that will be shown
            % and store the indici
            
            % fprintf('%s:startSequence\n',class(obj));
            sdeo = sequenceDispatchEngineClass.getEngine(true);
            sdeo.enableFrameRateEventSupport;
            obj.printFcn('Sequence ''%s'' at %s\n',...
                    obj.sequenceName,datestr(now,13));
            notify(obj,'SequenceStarted');
            obj.count = 0;
            obj.renderNextFrame();
            % obj.renderAllFrames();
        end
        
        function stopSequence(obj)
            notify(obj,'LastElement',...
                notificationEventClass('stopSequence'));
            % fprintf('Sequence aborted at %s\n',datestr(now));
            % Delete all textures used for this sequence
            if ~isempty(obj.gratingtex)
                Screen('close',obj.gratingtex);
                obj.gratingtex = [];
            end
        end
        
        function prepNextElement(obj)
            fprintf('prepNextElement\n');
            obj.renderNextFrame();
        end
        
        function nElemets = getNElements(obj)
            nElemets = obj.countTarget;
        end
        
        function reqTime = calculateSequenceTime(obj)
            reqTime = 10;
        end
        
        function descStrs = tellSequenceDetails(obj)
            % Figure out how many unique elements exist in the sequence
            descStrs = sprintf('driftGratingSequence:''%s'':',...
                obj.sequenceName);
        end
        
        function alignTiming(obj) %#ok<MANU>
            % don't do anything
        end
        
        function makeTextures(obj)
            % Setup to calculate gratings
            mp = obj.sio.getMonitorProfile;
            resolution = obj.sio.getScreenResolution(mp.number);
            cols = resolution.width;
            rows = resolution.height;
            res = [cols rows];
%             res = [400 300]
            
            % Build a procedural sine grating texture for a grating with a support of
            % res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.
            obj.gratingtex = CreateProceduralSineGrating(obj.sio.window, ...
                res(1), res(2), [0.5 0.5 0.5 0.0]);
            
            % Predefine phase values
            obj.phaseSteps = 100;
            % obj.phaseValues = linspace(0,2*pi,obj.phaseSteps);
            obj.phaseValues = 0
            obj.phaseIndex = 1;
            
            obj.freq = 1/360; % Spatial freq of the grating in cycles per pixel: Here 0.01 cycles per pixel:
            obj.angle = 45;
            
        end
        
        function renderNextFrame(obj)
            fprintf('%3i renderNextFrame\n',obj.count);
            
            rotateMode = kPsychUseTextureMatrixForRotation;
            
            amplitude = 0.5;
            
            %phaseincrement = 360 * ifi;
            obj.phaseValues = obj.phaseValues + 360 / 10; %(obj.phaseIndex);
            
%             obj.freq = obj.freq * 1.01;
%             obj.angle = obj.angle + pi/4;
            
            Screen('DrawTexture', obj.sio.window, obj.gratingtex,...
                [], [], obj.angle,[], [], [], [], rotateMode, ...
                [obj.phaseValues, obj.freq, amplitude, 0]);
            
            obj.sio.executePreFlipFncs;
            obj.phaseIndex = obj.phaseIndex + 1;
            if obj.phaseIndex > obj.phaseSteps
                obj.phaseIndex = 1;
            end
            obj.count = obj.count + 1;
            %obj.dispatchEngine.scheduleFlipRelativeToVBL(0,[]);
            if obj.count == obj.countTarget
                obj.stopSequence;
            else
                obj.dispatchEngine.flipNow([]);
            end
        end
        
        function renderAllFrames(obj)
            
            fprintf('%s.renderAllFrames starting\n',class(obj));
            drawnow

            rotateMode = kPsychUseTextureMatrixForRotation;
            freq = 1/360; % Spatial freq of the grating in cycles per pixel: Here 0.01 cycles per pixel:
            cyclespersecond = 1;            
            angle = 45;
            amplitude = 0.5;
            
            % fprintf('%3i renderNextFrame\n',obj.count);
            
            [~,ifi] = obj.sio.getMonitorRefreshRate(false);
            
            obj.phaseIndex = 1;
            phase = 0;
            phaseincrement = (cyclespersecond * 360) * ifi;
            
            % synchronize to screen refresh
            vbl = obj.sio.flipScreen;
            old = vbl;
            
            for theCount = 1:obj.countTarget
                
                phase = phase + phaseincrement;
                
                Screen('DrawTexture', obj.sio.window, obj.gratingtex,...
                    [], [], angle,[], [], [], [], rotateMode, ...
                    [phase, freq, amplitude, 0]);
                
                freq = freq * 1.01;
                angle = angle + pi/4;
                
                obj.sio.executePreFlipFncs;
                
                nextFlipTime = vbl + 0.95*ifi;
                vbl = obj.sio.flipScreen(nextFlipTime,0);
                
                fprintf('flipDelta = %1.5f, flipDelta = %1.4f\n',vbl-old,vbl-nextFlipTime);
                old = vbl;
                
                %
                %                 obj.phaseIndex = obj.phaseIndex + phaseincrement;
                %                 if obj.phaseIndex > obj.nSteps
                %                     obj.phaseIndex = 1;
                %                 end
                
            end
            obj.stopSequence;
        end
        
        
%         function renderNextFrame(obj)
%             % fprintf('%3i renderNextFrame\n',obj.count);
%             Screen('DrawTexture',obj.targetWindow,obj.textures(obj.phaseIndex),[],[],45);
%             obj.sio.executePreFlipFncs;
%             obj.phaseIndex = obj.phaseIndex + 1;
%             if obj.phaseIndex > obj.nSteps
%                 obj.phaseIndex = 1;
%             end
%             obj.dispatchEngine.scheduleFlipRelativeToVBL(0,[]);
%             obj.count = obj.count + 1;
%             if obj.count == obj.countTarget
%                 obj.stopSequence;
%             end
%         end
%         
%         function renderAllFrames(obj)
%             % fprintf('%3i renderNextFrame\n',obj.count);
%             
%             obj.phaseIndex = 1;
%             [~,ifi] = obj.sio.getMonitorRefreshRate(false);
%             vbl = obj.sio.flipScreen;
%             
%             for theCount = 1:obj.countTarget
%             
%                 Screen('DrawTexture',obj.targetWindow,...
%                     obj.textures(obj.phaseIndex),[],[],45);
%                 %obj.sio.executePreFlipFncs;
%                 
%                 nextFlipTime = vbl + 0.95*ifi;
%                 vbl = obj.sio.flipScreen(nextFlipTime,0);
%                 
%                 obj.phaseIndex = obj.phaseIndex + 1;
%                 if obj.phaseIndex > obj.nSteps
%                     obj.phaseIndex = 1;
%                 end
%             
%             end
%             obj.stopSequence;
%         end
%         
%         function makeTextures(obj)
%             % Setup to calculate gratings
%             mp = obj.sio.getMonitorProfile;
%             mH = mp.screen_height;
%             md = mp.viewing_distance;
%             resolution = obj.sio.getScreenResolution(mp.number);
%             cols = resolution.width;
%             rows = resolution.height;
%             sf = 0.05;
%             con = 100;
%             C = 0.017455064928218; % tan of 1 degree, approx 1 deg in radians
%             nCycles = mH*sf/(md*C);
%             nPix = ceil(sqrt(cols^2+rows^2)); % minimal size required to rotate without clipping
%             fp = nCycles*nPix/rows; % spacial frequency in pixels
%             pixelvec = fp*linspace(0,2*pi,nPix);
%             phaseValues = linspace(0,2*pi,obj.nSteps); % + mod(fp*pi,pi); % phase shift to center zero crossing on screen
%             obj.textures = zeros(1,obj.nSteps);
%             for iP = 1:obj.nSteps
%                 grating = obj.sio.gray*(1+(con/100)*repmat(sin(pixelvec-phaseValues(iP))',1,nPix));
%                 obj.textures(iP) = obj.sio.makeTexture(grating);
%             end
%             obj.phaseIndex = 1;
%         end
        
    end
    
end