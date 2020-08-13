classdef startleSessionManagerClass < sessionManagerClass
    
    properties
        isiPercentageRange
    end
    
    methods
        
        function obj = startleSessionManagerClass(varargin)
            obj = obj@sessionManagerClass(varargin{:});
            obj.isiPercentageRange = [0.5 1.5];
        end
        
        function interSeqInterval = getInterSeqInterval(obj)
            randPercent = (obj.isiPercentageRange(1) + ...
                diff(obj.isiPercentageRange)*rand);
            interSeqInterval = round(obj.interSeqInterval * randPercent);
            % fprintf('random percent = %1.2f time = %1.2f\n',...
            %     randPercent,interSeqInterval);
            obj.printFcn('   Next stimulus in %s at %s\n',...
                secs2Str(interSeqInterval),...
                datestr(now+datenum(0,0,0,0,0,interSeqInterval),13));
        end
        
        function setIsiPercentageRange(obj,range)
            if length(range) ~= 2
                obj.printFcn('Error: isiPercentageRange must have 2 elements');
                error('%s.setIsiPercentageRange: isiPercentageRange must have 2 elements',...
                    class(obj));
            end
            obj.isiPercentageRange = range;
        end
        
    end
end