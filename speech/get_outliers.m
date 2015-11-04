function [inds] = get_outliers(dataVals,word,fmt,frange,trange)
%GET_OUTLIERS  Get trials with ftrack values outside a given range.

if nargin < 5
    trange = ':';
end

outside = zeros(1,length(dataVals));
for i=1:length(dataVals)
    if dataVals(i).word == word && ~dataVals(i).bExcl
        if trange(end) < length(dataVals(i).(fmt)) % if end of range is within ftrack
            low = sum(dataVals(i).(fmt)(trange) < min(frange));
            high = sum(dataVals(i).(fmt)(trange) > max(frange));
        elseif trange(1) < length(dataVals(i).(fmt)) % if end of range is too high but beginning of range is within ftrack
            low = sum(dataVals(i).(fmt)(trange(1):end) < min(frange));
            high = sum(dataVals(i).(fmt)(trange(1):end) > max(frange));
        else % if ftrack is completely outside of range
            % unclear whether or not these should count as outliers --
            % use 'low = 0; high = 0;' instead?
            low = sum(dataVals(i).(fmt) < min(frange));
            high = sum(dataVals(i).(fmt) > max(frange));
        end
        outside(i) = low + high;
    end
end

inds = [dataVals(logical(outside)).token];
end