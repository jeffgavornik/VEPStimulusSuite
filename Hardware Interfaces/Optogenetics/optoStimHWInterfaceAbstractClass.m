classdef optoStimHWInterfaceAbstractClass < handle
    
    % Define an interface used to control optogenetic stimulus hardware
    
    methods (Abstract)
        
        isOpen = openInterface(obj)
        closeInterface(obj)
        isValid = validateInterface(obj)
        success = turnLightOn(obj)
        success = turnLightOff(obj)
        success = setLightLevel(obj,level)
        
    end
    
end