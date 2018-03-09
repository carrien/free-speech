function [inds] = get_outliers(dataVals,grouping,groupnum,fmt,frange,trange)
%GET_OUTLIERS  Get trials with ftrack values outside a given range.

if nargin < 2 || isempty(grouping), grouping = 'word'; end
if nargin < 6, trange = []; end

tstep = .003;

reply = input('Start trial? [1]: ','s');
if isempty(reply), reply = '1'; end
startTrial = sscanf(reply,'%d');

outside = zeros(1,length(dataVals));
for i=startTrial:length(dataVals)
    % only count good trials in the group
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
        low = sum(dataVals(i).(fmt)(indstart:indend) < min(frange));
        high = sum(dataVals(i).(fmt)(indstart:indend) > max(frange));
        outside(i) = low + high;
    end
end

inds = [dataVals(logical(outside)).token];
