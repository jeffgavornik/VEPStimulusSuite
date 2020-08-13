function handleWarning(ME,useGUI,errClass,fid,WaitForAcknowledgement)
% handleWarning(ME,useGUI,errClass,fid,WaitForAcknowledgement)
%
% Helper function to display information about an exception thrown inside a
% try/catch block.
%
% fid can be set to direct non-gui message, if empty defaults to stderr
%
% Set WaitForAcknowledgement to pause execution until user closes the
% warning
% 
% example usage:
%   function foo()
%   try
%       someCode();
%   catch ME
%       handleWarning(ME,true,'My Warning');
%       cleanupCode();
%   end
%
% ME can be an MException class object or a string

% ME is MException, db is the return value from dbstack
if nargin < 5 || isempty(WaitForAcknowledgement)
    WaitForAcknowledgement = false;
end
if nargin < 4 || isempty(fid)
    fid = 2;
end
if nargin < 3 || isempty(errClass)
    errClass = 'Stimulus Suite Exception Handler';
end
isAnException = isa(ME,'MException');
if isAnException
    % Ignore if the warning is being suppressed
    try
        warnState = warning('QUERY',ME.identifier);
    catch
        warnState.state = 'on';
    end
    if ~strcmp(warnState.state,'on')
        return;
    end
end
if isAnException
    fprintf(fid,'%s\n%s\n',errClass,getReport(ME));
else
    fprintf(fid,'%s\n%s\n',errClass,ME);
end
if nargin < 2 || useGUI
    if isAnException
        nS = length(ME.stack);
        if nS > 0
            msgStr = sprintf('%s\nWarning Message: ''%s''\nFunction Trace:',...
                errClass,ME.message);
            for iS = 1:nS
                msgStr = sprintf('%s\n   %s (line %i)',msgStr,...
                    ME.stack(iS).name,ME.stack(iS).line);
            end
        else
            msgStr = sprintf('%s\nWarning Message: ''%s''\n',...
                errClass,ME.message);
        end
    else
        msgStr = sprintf('%s\nWarning Message: ''%s''\n',...
            errClass,ME);
    end
    msgStr = sprintf('%s\n',msgStr);
    if WaitForAcknowledgement
        try %#ok<TRYNC>
            playAlertTone();
        end
        uiwait(warndlg(msgStr,errClass,'modal'));
    else
        warndlg(msgStr,errClass);
    end
end
drawnow
end