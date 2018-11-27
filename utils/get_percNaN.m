function [percNaN] = get_percNaN(tracks)
%GET_PERCNAN  Return %NaN values at each timepoint (row).

ntimepts = size(tracks,1);
ntrials = size(tracks,2);

percNaN = zeros(ntimepts,1);
for t = 1:ntimepts % for each timepoint
    thistime = tracks(t,:);
    nNaNs = sum(isnan(thistime)); % #NaNs
    percNaN(t) = nNaNs/ntrials;
end
