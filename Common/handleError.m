function handleError(ME,useGUI,errClass,fid,WaitForAcknowledgement)
% handleError(ME,useGUI,errClass,fid,WaitForAcknowledgement)
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
%       handleError(ME,true,'My Error');
%       cleanupCode();
%   end

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
fprintf(fid,'%s:\n%s\n',errClass,getReport(ME));
if nargin < 2 || useGUI
    nS = length(ME.stack);
    if nS > 0
        msgStr = sprintf('%s\nError Message: ''%s''\nFunction Trace:',...
            errClass,ME.message);
        for iS = 1:nS
            msgStr = sprintf('%s\n   %s (line %i)',msgStr,...
                ME.stack(iS).name,ME.stack(iS).line);
        end
    else
        msgStr = sprintf('%s\nError Message: ''%s''\n',...
            errClass,ME.message);
    end
    msgStr = sprintf('%s\n',msgStr);
    if WaitForAcknowledgement
        try %#ok<TRYNC>
            playAlertTone();
        end
        uiwait(errordlg(msgStr,errClass,'modal'));
        % dbstop(ME) % good in theory but can't get it to work...
    else
        errordlg(msgStr,errClass);
    end
end
drawnow
end