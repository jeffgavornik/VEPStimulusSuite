classdef optoSessionManagerClass < sessionManagerClass
    
    methods
        
        function startPresentation(obj,varargin)
            obj.dispatchEngine.lowResTimerAccuracy = 0.1;
            startPresentation@sessionManagerClass(obj);
        end
        
        function stopPresentation(obj,varargin)
            % Make sure that the laser is turned off when stopping a
            % presentation
            stopPresentation@sessionManagerClass(obj,varargin{:});
            TurnOptoStimLaserOff();
        end
        
    end
    
end