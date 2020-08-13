classdef scaEventClass < handle
    % Class to support event handling associated with the ScrnCtrlApp
    
    properties
        hObject
    end
    
    events
        UserAbort
        FunctionCompleted
        ExitApp
    end
    
    methods
        
        function obj = scaEventClass(hObject)
            obj.hObject = hObject;
        end
        
    end
    
end
