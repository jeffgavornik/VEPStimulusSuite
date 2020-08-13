function cleanup
% Attempts to close all figures and clear everything, including orphaned
% objects

state = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles', 'on');
hFigs = get(0,'children');
for iF = 1:numel(hFigs)
    handles = guidata(hFigs(iF));
    if isfield(handles,'figure1')
        delete(handles.figure1);
    else
        delete(hFigs(iF));
    end
end
set(0,'ShowHiddenHandles',state);

ud = get(0,'UserData');
if isa(ud,'containers.Map')
    keys = ud.keys;
    for iK = 1:length(keys)
        try delete(ud(keys{iK})); end  %#ok<TRYNC>
    end
end
delete(ud)
set(0,'UserData',[]);

evalin('base','clear all');
delete(timerfindall)
evalin('base','clear classes');
evalin('base','clear mex');
evalin('base','clear functions');
evalin('base','clear java');