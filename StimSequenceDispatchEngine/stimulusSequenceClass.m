classdef stimulusSequenceClass < abstractSequenceClass
    
    % Groups distinct events that constitute an image sequence together
    
    properties
        elements % cell array of sequence elements
        index % index into elements array of current element
        count % counts presented elements
        nElements % the number of elements during a presentation run
        elementOrder % define the order in which the elements are presented
        repeatCounter % keep track of sequence repeats
        nRepeats % define number of sequence repeats
        
        currentHoldTime
        % Allow the sequence to override the event values
        eventValueOverride
        eventOverrideValues
    end
    
    methods
        
        function obj = stimulusSequenceClass(sequenceName)
            try
            %fprintf('creating class %s\n',class(obj));
            obj.elements = {};
            obj.elementOrder = [];
            obj.index = 0;
            obj.count = 0;
            obj.nElements = 0;
            if nargin == 1
                obj.sequenceName = sequenceName;
            end
            obj.repeatCounter = 0;
            obj.nRepeats = 0;
            % obj.printFcn = @fprintf;
            obj.scaSupport = false;
            obj.eventValueOverride = false;
            obj.eventOverrideValues = [];
            catch ME
                handleError(ME,true,obj.configFailErrorID,[],true);
            end
        end
        
        function delete(obj)
           for iE = 1:obj.nElements
               delete(obj.elements{iE});
           end
        end
        
        function addSequenceElements(obj,seos)
            % Add sequenceElementClass objects to the sequence
            n = numel(obj.elements); % current number of elements
            newIndici = n+(1:numel(seos));
            obj.elements(newIndici) = seos;
            obj.elementOrder(newIndici) = newIndici;
            obj.nElements = numel(obj.elementOrder);
        end
        
        function seo = addNewSequenceElement(obj,seo)
            if ~isa(seo,'sequenceElementClass')
                error('Passed object is not an instance of sequenceElementClass');
            end
            obj.addSequenceElements({seo});
        end
        
        function setElementPresentationOrder(obj,elementOrder)
            % Override the default presentation order manually (which is 
            % to present the elements in the same order they were added)
            obj.elementOrder = elementOrder;
            obj.nElements = numel(obj.elementOrder);
        end
        
        function setElementOrder(obj) %#ok<MANU>
            % Called by the startSequence method, defualt behavior is to do
            % nothing - override to set the sequence order at runtime
        end
        
        function setRepeatNumber(obj,repeatNumber)
            % Note: repeat number 0 means the sequence will display 1 time,
            % repeat number 1 means it will display twice, etc.
            obj.nRepeats = repeatNumber;
        end
        
        function setNumberOfPresentations(obj,n)
            if n<=0
                n = 1;
            end
            obj.nRepeats = n-1;
        end
        
        function alignTiming(obj)
            for iE = 1:length(obj.elements)
                obj.elements{iE}.alignTiming;
            end
        end
        
        function startSequence(obj)
            % fprintf('%s:startSequence\n',class(obj));
            sio = screenInterfaceClass.returnInterface;
            obj.targetWindow = sio.window;
            obj.printFcn('Sequence ''%s'' at %s\n',...
                    obj.sequenceName,datestr(now,13));
            notify(obj,'SequenceStarted');
            obj.repeatCounter = 0;
            obj.count = 1;
            setElementOrder(obj);
            obj.index = obj.elementOrder(1);
            issueDrawCommands(obj.elements{obj.index},obj.targetWindow);
            obj.currentHoldTime = obj.elements{obj.index}.holdTime;
            flipNow(obj.dispatchEngine,obj.elements{obj.index}.flipFnc);
        end
        
        function stopSequence(obj)
            %notify(obj,'SequenceComplete',...
            %    notificationEventClass('stopSequence'));
            notify(obj,'LastElement',...
                notificationEventClass('stopSequence'));
            obj.count = 0;
            obj.index = 0;
            % fprintf('Sequence aborted at %s\n',datestr(now));
        end
        
        function prepNextElement(obj)
            %fprintf('%s:prepNextElement\n',class(obj));
            % Use the hold time from the last element to schedule the
            % next element's flip time
            %try
            obj.count = obj.count + 1;
            % The count is less than the number of elements in the sequence
            if obj.count <= obj.nElements
                %fprintf('case 1 count = %i\n',obj.count)
                obj.index = obj.elementOrder(obj.count);
                issueDrawCommands(obj.elements{obj.index},obj.targetWindow);
                holdTime = obj.currentHoldTime;
                obj.currentHoldTime = obj.elements{obj.index}.holdTime;
                scheduleFlipRelativeToVBL(obj.dispatchEngine,...
                    holdTime,obj.elements{obj.index}.flipFnc);
            elseif obj.repeatCounter < obj.nRepeats
                %fprintf('case 2 count = %i\n',obj.count)
                obj.repeatCounter = obj.repeatCounter + 1;
                setElementOrder(obj);
                obj.count = 1;
                obj.index = obj.elementOrder(1);
                issueDrawCommands(obj.elements{obj.index},obj.targetWindow);
                obj.currentHoldTime = obj.elements{obj.index}.holdTime;
                holdTime = obj.elements{obj.elementOrder(end)}.holdTime;
                scheduleFlipRelativeToVBL(obj.dispatchEngine,...
                    holdTime,obj.elements{obj.index}.flipFnc);
            else
                %fprintf('case 3 count = %i\n',obj.count)
                % Schedule a last flip with no draw commands - this will
                % make sure the last element stays on the screen the
                % correct duration
                scheduleFlipRelativeToVBL(obj.dispatchEngine,...
                    obj.elements{obj.elementOrder(end)}.holdTime,[]);
                obj.count = 0;
                obj.index = 0;
                notify(obj,'LastElement');
            end
            %catch ME
            %    fprintf(2,'prepNextElement\n:%s\n',getReport(ME));
            %end
        end
        
        function nElemets = getNElements(obj)
            nElemets = obj.nElements * (obj.nRepeats + 1);
        end
        
        function reqTime = calculateSequenceTime(obj)
            reqTime = 0;
            for iE = 1:numel(obj.elementOrder)
                theElement = obj.elements{obj.elementOrder(iE)};
                reqTime = reqTime + theElement.holdTime;
            end
            reqTime = reqTime * (obj.nRepeats+1);
        end
        
        function descStrs = tellSequenceDetails(obj)
            % Figure out how many unique elements exist in the sequence
            evntVals = zeros(1,obj.nElements);
            for iE = 1:obj.nElements
                elmt = obj.elements{iE};
                evntVals(iE) = elmt.eventValue;
            end
            [uniqueEvs,iFirst] = unique(evntVals);
            nUnique = length(uniqueEvs);
            
            descStrs = cell(1);
            descStrs{1} = sprintf('Sequence:''%s'',%i elements (%i unique):',...
                obj.sequenceName,obj.nElements,nUnique);
            for iE = 1:nUnique
                elmt = obj.elements{iFirst(iE)};
                descStrs{end+1} = sprintf('%i:%s',...
                    iE,elmt.tellElementDetails); %#ok<AGROW>
            end
        end
        
    end
    
end