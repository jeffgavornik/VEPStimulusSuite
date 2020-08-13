classdef screenAlignedTimeClass < handle
    % Class that will automatically align defined timing properties with
    % the screen refresh rate
    
    properties (Hidden=true)
        % When true, the time variable will be set as integer multiples of
        % the screen refresh rate by alignTiming()
        alignWithScreenRefreshRate = true;
        % The sequence will automatically align timing of all properties
        % whose names are listed in the following cell array, see
        % alignTiming method for more details
        timeVariablesNeedingAlignment = {};
    end
    
    methods
        
        function alignTiming(obj)
            try
                if obj.alignWithScreenRefreshRate
                    sio = screenInterfaceClass.returnInterface;
                    [~,ifi] = sio.getMonitorRefreshRate;
                    if isempty(ifi)
                        error('%s.alignTiming: ifi is empty',class(obj));
                    end
                    for iV = 1:length(obj.timeVariablesNeedingAlignment)
                        param = obj.timeVariablesNeedingAlignment{iV};
                        remainder = rem(obj.(param),ifi);
                        if remainder ~= 0
                            obj.(param) = obj.(param) + ifi - remainder;
                        end
                    end
                end
            catch ME
                handleError(ME,false,'timing alignment failure');
            end
            
        end
        
        function set.timeVariablesNeedingAlignment(obj,propNames)
           if ~isa(propNames,'cell')
               propNames= {propNames};
           end
           goodVals = true(1,length(propNames));
           for iP = 1:length(propNames)
               propName = propNames{iP};
               try
                   if ~ isprop(obj,propName)
                       goodVals(iP) = false;
                       error('%s is not a property variable of %s',...
                           propName,class(obj));
                   end
               catch ME
                   handleError(ME,true,'Timing config error');
               end
           end
           obj.timeVariablesNeedingAlignment = propNames(goodVals);
        end
        
    end
    
    
end