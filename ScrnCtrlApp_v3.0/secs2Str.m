function hmsStr = secs2Str(secs)
% hmsStr = secs2Str(secs)
%   hmsStr is a string formatted as '%i hours, %i mins, %1.2f secs'

hours = floor(secs/3600);
secs = secs - hours*3600;
mins = floor(secs/60);
secs = secs - mins*60;
if hours
    hmsStr = sprintf('%i hours, %i mins, %1.2f secs',hours,mins,secs);
elseif mins
    hmsStr = sprintf('%i mins, %1.2f secs',mins,secs);
else
    hmsStr = sprintf('%1.2f secs',secs);
end
