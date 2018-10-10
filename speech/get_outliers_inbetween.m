function [inds] = get_outliers_inbetween(dataVals,grouping,groupnum,fmt,frange,trange,bExcl)
%GET_OUTLIERS  Get trials with ftrack values outside a given range.

if nargin < 2 || isempty(grouping), grouping = 'word'; end
if nargin < 6, trange = []; end
if nargin < 7 || isempty(bExcl), bExcl = 1; end

tstep = .003;

outside = zeros(1,length(dataVals));
for i=1:length(dataVals)
    if ~bExcl, dataVals(i).bExcl = 0; end % only count good trials in the group unless bExcl = 0
    if dataVals(i).(grouping) == groupnum && ~dataVals(i).bExcl
        % get track length
        len = length(dataVals(i).(fmt));
        taxis = tstep.*(0:len-1);
        if ~isempty(trange)
            indstart = get_index_at_time(taxis,trange(1));
            indend = get_index_at_time(taxis,trange(end));
        else
            indstart = 1;
            indend = len;
        end
        % look for outliers
         low = sum(dataVals(i).(fmt)(indstart:indend) < max(frange))
         high = sum(dataVals(i).(fmt)(indstart:indend) > min(frange))
         if low  > 1 && high > 1
        outside(i) = 1
         end
    end
end

inds = [dataVals(logical(outside)).token];
