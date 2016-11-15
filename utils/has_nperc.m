function [hasnp] = has_nperc(tracks,n)
%HAS_NPERC  Find timepoints (rows) with fewer than N% NaN values.

ntimepts = size(tracks,1);
hasnp = zeros(ntimepts,1);
for t = 1:ntimepts % for each timepoint
    thistime = tracks(t,:); nonans = thistime(~isnan(thistime)); % remove NaNs
    if length(nonans)>length(thistime)*(n/100)
        hasnp(t) = 1; % 1 at each timepoint with fewer than n% of trials NaN
    end
end
