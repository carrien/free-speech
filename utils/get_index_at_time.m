function [ind] = get_index_at_time(taxis,t,roundtype)
%GET_INDEX_AT_TIME  Return index into time axis at specified time.
%   GET_INDEX_AT_TIME(TAXIS,T,ROUNDTYPE) runs a simple binary search to
%   find the index into a time axis TAXIS corresponding to a time value T.
%   ROUNDTYPE determines whether the index is rounded up ('ceil') or down
%   ('floor'), or if the closest value is used ('round').

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