classdef daqHardwareAbstractClass < handle
    % Define an interface for a DAQ
    % This interface is similar to the TTL interface but more full
    % functioned.  It might make sense to have the ttlInterface be a
    % subclass of DAQ, but this might also cause problems when the same
    % hardware is used for both TTL and DAQ.  It is also possible these
    % problems will result when a single hardware is being used both for
    % TTL and DAQ functions simultaneously...
    
    
    properties (Constant,Hidden=true)
        digitalOutWarningID = 'DAQ:AOSupport';
        digitalInWarningID = 'DAQ:AISupport';
        analogOutWarningID = 'DAQ:AOSupport';
        analogInWarningID = 'DAQ:AISupport';
    end
    
    
    methods (Abstract)
        
        isOpen = openInterface(obj)
        success = writeAnalog(obj,varargin)
        data = readAnalog(obj,varargin)
        success = writeDigital(obj,varargin)
        data = readDigital(obj,varargin)
        isValid = validateInterface(obj,varargin)
        
    end
    
end