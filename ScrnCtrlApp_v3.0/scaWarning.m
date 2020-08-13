function scaWarning(varargin)
% Wrapper around ScrnCtrlApp's notifyOfWarning() to allow standard
% fprintf calling conventions

ScrnCtrlApp('notifyOfWarning',{sprintf(varargin{:})});
