function setWarningStateForClass(classNameStr,onOrOff)
% Method that looks for all properties in the class with name classNameStr
% that have WarningID in their name and supresses/allows warnings

props = properties(classNameStr);
for iP = 1:length(props)
    propName = props{iP};
    if stcmpi(propName,'WarningID')
        try
            propStr = sprintf('%s.%s',classNameStr,propName);
            warnID = eval(propStr);
            warning(onOrOff,warnID);
        catch
            
            fdbkStr = sprintf('Set Warning to state %s failed for %s',...
                onOrOff,propStr);
            if exist('warnID','var')
                fdbkStr = sprintf('%s=%s\n',warnID);
            else
                fdbkStr = sprintf('%s\n',fdbkStr);
            end
            fprintf(fdbkStr);
        end
    end
end

