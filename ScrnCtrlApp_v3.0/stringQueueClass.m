classdef stringQueueClass < handle
	% Class that holds a cell array of strings and can return them in
	% either a FIFO or FILO manner
    
    properties (Access=private)
        cellArray
        timeStamps
        ptr
        baseArraySize = 500; % default size of array
        arraySize % actual size, can be resized on overflow
    end
    
    methods
        
        function obj = stringQueueClass()
            obj.flush;
        end
        
        function addString(obj,value)
            if ~iscell(value)
                value = {value};
            end
            timestamp = datestr(now,13);
            n = numel(value);
            for ii = 1:n
                % Check for overflow and reallocate if needed
                if obj.ptr > obj.arraySize
                    obj.increaseBuffer;
                end
                obj.cellArray{obj.ptr} = value{ii};
                obj.timeStamps{obj.ptr} = timestamp;
                obj.ptr = obj.ptr + 1;
            end
        end
        
        function [elements,timestamps] = returnFILO(obj)
            % return elements in first-in last-out order
            elements = obj.cellArray(obj.ptr-1:-1:1);
            timestamps = obj.timeStamps(obj.ptr-1:-1:1);
        end
        
        function [elements,timestamps] = returnFIFO(obj)
            % return elements in first-in first-out order
            elements = obj.cellArray(1:obj.ptr-1);
            timestamps = obj.timeStamps(1:obj.ptr-1);
        end
        
        function flush(obj)
            obj.cellArray = cell(1,obj.baseArraySize);
            obj.timeStamps
            obj.arraySize = obj.baseArraySize;
            obj.ptr = 1;
        end
        
    end
    
    methods (Access=private)
        
        function increaseBuffer(obj)
            % Increase the size of the array
            obj.cellArray = [obj.cellArray cell(1,obj.baseArraySize)];
            obj.timeStamps = [obj.timeStamps cell(1,obj.baseArraySize)];
            obj.arraySize = obj.arraySize + obj.baseArraySize;
        end
        
    end
    
end
        
        
        
