function scaPrintf(varargin)
% Wrapper around ScrnCtrlApp's displayMessage() to allow standard
% fprintf calling conventions

ScrnCtrlApp('displayMessage',{sprintf(varargin{:})});
