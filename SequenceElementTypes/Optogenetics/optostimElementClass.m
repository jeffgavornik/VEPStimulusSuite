classdef optostimElementClass < sequenceElementClass
    % Extends sequence element class to provide timed audio stimulus within
    % a sequence
    
    properties
        pulseWidth = 0.05;
        pulseTrainDuration = 0; % set zero for infinite
    end
    
    properties (SetAccess=private,Hidden=true)
        % Optostim hardware interface
        osi
    end
    
    methods
        
        function obj = optostimElementClass()
            obj.osi = optoStimHWInterfaceClass.getInterface;
            setFunction(obj,'pulse',0.1); % 100 ms pulse default
        end
        
%         function issueDrawCommands(obj,targetWindow)
%             % setEventWord(obj.ttlInterface,obj.eventValue);
%             % Use inherited draw routine
%             disp('issueDrawCommands')
%             issueDrawCommands@sequenceElementClass(obj,targetWindow);
%         end
        
        function setFunction(obj,fncStr,varargin)
            % Set the flip function
            % LaserOn, LaserOff use optoStimHWInterface and should work for
            % either analog or digital configuration (assuming everything
            % is configured correctly)
            % DigitalOn and DigitalOff set digital output directly
            % AnalogOn and AnalogOff set analog power level directly,
            % assume power level is varargin{1}
            % Pulse is a single pulse with specified width (varargin{1})
            % and optional power setting (varargin{2}), see pulseLaser
            % PulseTrain uses the nPulses (varargin{1}) with specified
            % pulse width (pre-set or varargin{2}), see pulseTrain
            args = varargin;
            switch lower(fncStr)
                case 'laseron'
                    disp('setFunction = turnOnLaser')
                    obj.flipFnc = @(varargin)turnLightOn(obj.osi);
                case 'laseroff'
                    disp('setFunction = turnOffLaser')
                    obj.flipFnc = @(varargin)turnLightOff(obj.osi);
                    %                 case 'digitalon'
                    %                     obj.flipFnc = @(varargin)digitalOn(obj);
                    %                 case 'digitaloff'
                    %                     obj.flipFnc = @(varargin)digitalOff(obj);
                case 'pulse'
                    obj.flipFnc = @(varargin)pulseLaser(obj,args{:});
                    %                 case 'pulsetrain'
                    %                     obj.flipFnc = @(varargin)pulseTrain(obj,args{:});
                    %                 case 'analogon'
                    %                     obj.flipFnc = @(varargin)analogLevelOn(obj,args{1});
                    %                 case 'analogoff'
                    %                     obj.flipFnc = @(varargin)analogLevelOff(obj);
                case 'startpulsetrain'
                    obj.flipFnc = @(varargin)startPulseTrain(obj.osi,...
                        obj.pulseWidth,obj.pulseTrainDuration);
                case 'stoppulsetrain'
                    obj.flipFnc = @(varargin)stopPulseTrain(obj.osi);
                otherwise
                    fprintf('%s.setFunction: unknown function type %s\n',...
                        class(obj),fncStr);
            end
        end
        
    end
    
    properties (Access=private)
        usbObj
    end
    
    methods %(Access=private)
        %         function turnOnLaser(obj,varargin)
        %             disp('turnOnLaser')
        %             if nargin == 1
        %                 commandLaser(obj.osi,'on');
        %             else
        %                 commandLaser(obj.osi,varargin{:});
        %             end
        %         end
        %
        %         function turnOffLaser(obj)
        %             commandLaser(obj.osi,'off');
        %         end
        %
        %         function digitalOn(obj)
        %             setEventWord(obj.usbObj,1)
        %         end
        %
        %         function digitalOff(obj)
        %             setEventWord(obj.usbObj,0)
        %         end
        %
        function pulseLaser(obj,pulseWidth)
            if nargin < 2 || ~isempty(pulseWidth)
                pulseWidth = obj.pulseWidth;
            end
            obj.osi.turnLightOn;
            WaitSecs(pulseWidth);
            obj.osi.turnLightOff;
        end
        
        %         function pulseTrain(obj,nPulses,pulseWidth,power)
        %             if nargin < 2 || isempty(nPulses)
        %                 error('optostimElementClass.pulseTrain function requires 2 inputs');
        %             end
        %             if nargin >= 3 && ~isempty(pulseWidth)
        %                 obj.pulseWidth = pulseWidth;
        %             end
        %             if nargin < 4
        %                 for iP = 1:nPulses
        %                     WaitSecs(obj.pulseWidth);
        %                     pulseLaser(obj);
        %                 end
        %             else
        %                 for iP = 1:nPulses
        %                     WaitSecs(obj.pulseWidth);
        %                     pulseLaser(obj,[],power);
        %                 end
        %             end
        %         end
        %
        %         function analogLevelOn(obj,value)
        %             setAnalogLevel(obj.usbObj,value);
        %         end
        %
        %         function analogLevelOff(obj)
        %             setAnalogLevel(obj.usbObj,0);
        %         end
    end
    
end

