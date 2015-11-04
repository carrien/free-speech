function [inds] = get_trials_in_range(dataVals,word,fmt,frange,trange)
%GET_TRIALS_IN_RANGE  Get trials with ftrack values inside a given range.

if nargin < 5
    trange = ':';
end

trials_in_range = zeros(1,length(dataVals));
for i=1:length(dataVals)
    if dataVals(i).word == word && ~dataVals(i).bExcl
        if trange(end) < length(dataVals(i).(fmt)) % if end of range is within ftrack
            trials_in_range(i) = sum(min(frange) < dataVals(i).(fmt)(trange) & dataVals(i).(fmt)(trange) < max(frange));
        elseif trange(1) < length(dataVals(i).(fmt)) % if end of range is too high but beginning of range is within ftrack
            trials_in_range(i) = sum(min(frange) < dataVals(i).(fmt)(trange(1):end) & dataVals(i).(fmt)(trange(1):end) < max(frange));
        else % if ftrack is completely outside of range, do nothing
        end
    end
end

inds = [dataVals(logical(trials_in_range)).token];
end