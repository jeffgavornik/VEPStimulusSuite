function nameStr = fncNameStr(showLineNumber,fid)
% Helper to return the name of the calling function
% If showLineNumber is true, also include the line number
% If fid is defined, will print to fid as well

if nargin < 1 || isempty(showLineNumber)
    showLineNumber = false;
end

nameStr = '';
st = dbstack;
if length(st)>1
    nameStr = st(2).name;
    if showLineNumber
        nameStr = sprintf('%s (line %i)',nameStr,st(2).line);
    end
end

if nargin >1 && ~isempty(fid)
    fprintf(fid,'%s\n',nameStr);
end