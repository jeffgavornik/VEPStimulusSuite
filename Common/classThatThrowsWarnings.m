classdef classThatThrowsWarnings < handle
    % Class that will try to suppress or enable warnings for all constant 
    % properties that have the name *WarningID*
    %
    % eg: Properties (Constant)
    %       myWarningID = 'myClass:warningType';
    %     end
    
    methods (Static)
        
        function warnIDs = returnWarningIDs(objNameStr)
            mc = meta.class.fromName(objNameStr);
            props = mc.PropertyList;
            warnIDs = cell(1,length(props));
            count = 0;
            for iP = 1:length(props)
                propName = props(iP).Name;
                if regexpi(propName,'WarningID')
                    count = count + 1;
                    warnIDs{count} = eval([objNameStr '.' propName]);
                end
            end
            warnIDs = warnIDs(1:count);
        end
        
        function setWarningState(objNameStr,newState)
            switch lower(newState)
                case {'on' 'off'}
                otherwise
                    error('%s.setWarningState newState must be ''On'' or ''Off''\n');
            end
            warnIDs = classThatThrowsWarnings.returnWarningIDs(objNameStr);
            for iW = 1:length(warnIDs)
                warnID = warnIDs{iW};
                try
                    warning(newState,warnID);
                catch
                    fdbkStr = sprintf('%s.setWarningState Set Warning to state %s failed for %s\n',...
                        class(objNameStr),newState,warnID);
                    fprintf(fdbkStr);
                end
            end
        end
        
        function trueOrFalse = warningsAreSuppressedForClass(classNameStr)
            trueOrFalse = true;
            warnIDs = classThatThrowsWarnings.returnWarningIDs(classNameStr);
            for iW = 1:length(warnIDs)
                try %#ok<TRYNC>
                    warnState = warning('QUERY',warnIDs{iW});
                    trueOrFalse = trueOrFalse * strcmp(warnState.state,'off');
                end
            end
        end
        
    end
    
    methods
        
        function hideWarnings(obj,trueOrFalse)
            if nargin == 1
                trueOrFalse = true;
            end
            if trueOrFalse
                obj.setWarningState(class(obj),'off');
            else
                obj.setWarningState(class(obj),'on');
            end
        end
        
        function trueOrFalse = warningsAreSuppressed(obj)
            trueOrFalse = obj.warningsAreSuppressedForClass(class(obj));
        end
        
    end
    
end

