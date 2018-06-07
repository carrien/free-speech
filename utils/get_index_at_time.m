function [ind] = get_index_at_time(taxis,t,roundtype)

if nargin < 3, roundtype = 'round'; end

low = 1;
high = length(taxis);

% find flanking indices
while (high - low > 1)
    cand_ind = round((high+low)/2);
    if t < taxis(cand_ind)
        high = cand_ind;
    else
        low = cand_ind;
    end
end

% choose higher or lower index
switch roundtype
    case 'round'
        if abs(taxis(high)-t) > abs(taxis(low)-t)
            ind = low;
        else
            ind = high;
        end
    case 'ceil'
        ind = high;
    case 'floor'
        ind = low;
end