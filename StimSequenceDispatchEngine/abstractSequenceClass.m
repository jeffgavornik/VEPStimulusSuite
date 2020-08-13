classdef abstractSequenceClass < handle
    % Define the methods that all TTL interfaces must support in order to
    % be compliant with the StimulusSuite environment.  See
    % ttlInterfaceClass for more details.
    
    events
        % sequenceDispatchEngine listens for, and responds to, the
        % following events that should be posted when a sequence starts,
        % upon rending of the last elements, and when the sequence is
        % complete
        SequenceStarted
        LastElement
        SequenceComplete
    end
    
    properties
        sequenceName = 'Unnamed'
    end
    
    properties (Constant,Hidden=true)
        configFailErrorID = 'sequenceClass:configError';
    end
    
    properties (Hidden=true,Access=protected)
        % Use obj.printFcn(string) to print within the sequence.  This
        % should automatically direct output to the ScrnCtrlApp for logging
        % when it is in-use
        printFcn = @fprintf
        % Use obj.provideSCASupport to link execution with ScrnCtrlApp
        scaSupport
        % All render commands should use targetWindow, which is assigned
        % using the screenInterface
        targetWindow
        % dispatchEngine
        dispatchEngine
    end
        
    methods (Abstract)
        
        startSequence(obj)
        
        stopSequence(obj)
        
        % prepNextElement should issue all draw commands required before
        % the next flip command is issued, which will be scheduled based on
        % the specific sequence requirements
        prepNextElement(obj)
                
        % Return an estimate (in seconds) of how long it will take to run
        % the sequence
        reqTime = calculateSequenceTime(obj)
        
        % Return a string that describes the sequence
        descStrs = tellSequenceDetails(obj)
        
        % Figure out any timing variables that need to be set based on the
        % screen refresh rate
        alignTiming(obj)
        
    end
    
    methods
        
        function provideSCASupport(obj)
            if ~obj.scaSupport
                % Interface with the ScrnCtrlApp
                obj.scaSupport = true;
                obj.printFcn = @scaPrintf;
                for iE = 1:numel(obj.elements)
                    theElement = obj.elements{iE};
                    provideSCASupport(theElement);
                end
            end
        end
        
        function setDispatchEngine(obj,sdeo)
            obj.dispatchEngine = sdeo;
        end
        
        function set.sequenceName(obj,name)
            if ~isa(name,'char')
                error('%s.sequenceName must be class char',class(obj));
            end
            obj.sequenceName = name;
        end
        
    end
    
end