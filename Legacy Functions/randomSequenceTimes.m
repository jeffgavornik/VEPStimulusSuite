function randTimes = randomSequenceTimes(baseTimes,percentRange,constantEnvelope)
% Create radom sequence times from a base sequence
% 
% baseTimes are the base times for the sequence
% percentRange is a 1x2 matrix of low and high percents that defines a
%    window for the new random times (so if the new times should be within
%    25% of the old times, use [0.75 1.25])
% constantEnvelope will constrain the new sequence to take the same
%    cumulative amount of time as the base sequence if set to true

if size(percentRange) ~= size([1 1])
    error('percentRange must by 1x2 array');
end

width = diff(percentRange);
randTimes = zeros(size(baseTimes));
nT = numel(baseTimes);
for iT = 1:nT
    % Generate a random percentage in the specified range
    randPercent = (percentRange(1) + width*rand);
    % If constrained, the last time is the difference between the total
    % time of the base sequence and the cumulative time of the first
    % elements of the new random sequence 
    if constantEnvelope && iT == nT
        constrainedTime = sum(baseTimes) - sum(randTimes);
        % Check to make sure the constrained time is within the percentage
        % range.  If not, start over
        actualPercent = constrainedTime / baseTimes(nT);
        if actualPercent < percentRange(1) || ...
                actualPercent > percentRange(2)
            randTimes = randomSequenceTimes(baseTimes,percentRange,...
                constantEnvelope);
        else
            randTimes(iT) = constrainedTime;
        end
    else
        randTimes(iT) = baseTimes(iT) * randPercent;
    end
end