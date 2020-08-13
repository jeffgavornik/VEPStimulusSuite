classdef fixationPointClass < singletonClass & storedPreferenceClass
    % Defines and renders fixation point in the middle of a screen
    % Does not support multi-monitor setups.  Will remember color changes
    % from instance to instance
    %
    % Use examples:
    %
    % fixationPointClass.displayFixationPoint
    % fixationPointClass.hideFixationPoint
    % fixationPointClass.setColor([255 0 0]);
    % fixationPointClass.deleteObject();
    
    properties (SetObservable,AbortSet)
        color
    end
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'fixationPointClass';
        defaultColor = [255 255 0];
    end
    
    properties (Access=private)
        elements
        sio
        showFixationPoint
    end
    
    methods (Static)
        
        function fpo = getObject
            fpo = [];
            try %#ok<TRYNC>
                userData = get(0,'UserData');
                fpo = userData(fixationPointClass.singletonDesignatorKey);
            end
            if isempty(fpo)
                fpo = fixationPointClass;
            end
        end
        
        function displayFixationPoint
            fpo = fixationPointClass.getObject;
            if ~fpo.showFixationPoint
                fpo.showFixationPoint = true;
                fpo.sio.addPreFlipAction('FixPoint',...
                    @(hObj)render(fpo));
                fpo.sio.flipScreen;
            end
        end
        
        function hideFixationPoint
            fpo = fixationPointClass.getObject;
            if fpo.showFixationPoint
                fpo.showFixationPoint = false;
                fpo.sio.removePreFlipAction('FixPoint');
                fpo.sio.flipScreen;
            end
        end
        
        function setColor(color)
            if nargin == 0
                color = fixationPointClass.defaultColor;
            end
            if numel(color) == 1
                color = color * [1 1 1];
            end
            if numel(color) ~= 3
                error('color must be either a scalar or RGB triplet');
            end
            fpo = fixationPointClass.getObject;
            fpo.color = color;
            if fpo.showFixationPoint
                fpo.sio.flipScreen;
            end
        end
        
        function deleteObject
            userData = get(0,'UserData');
            if userData.isKey(fixationPointClass.singletonDesignatorKey)
                fixationPointClass.hideFixationPoint;
                delete(fixationPointClass.getObject);
            end
        end
        
    end
    
    methods (Access=private)
        
        function obj = fixationPointClass(varargin)
            disp('fpo constrict')
            if obj.singletonNeedsConstruction
                disp('Constructing fixationClassObject');
                obj.preferencePropertyNames = {'color'};
                obj.loadSavedPreferences;
                obj.listenForPreferenceChanges;
                obj.sio = screenInterfaceClass.returnInterface;
                obj.showFixationPoint = false;
                defineFixationPoint(obj,varargin);
            end
        end
        
        function render(obj,window)
            if nargin == 1
                window = obj.sio.window;
            end
            Screen('FillRect',window,obj.color,obj.elements{1});
            Screen('FillRect',window,obj.color,obj.elements{2});
        end
        
        function defineFixationPoint(obj,screenNumber)
            if nargin == 1
                screenNumber = [];
            end
            resolution = obj.sio.getScreenResolution(screenNumber);
            xC = floor(resolution.width/2);
            yC = floor(resolution.height/2);
            bW = 30 / 2;
            bH = 6 / 2;
            obj.elements{1} = [xC yC xC yC] + [-bH -bW bH bW];
            obj.elements{2} = [xC yC xC yC] + [-bW -bH bW bH];
        end
        
    end
    
    
end