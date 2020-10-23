function snum = get_snum(snum)

if nargin < 1, snum = []; end
if isempty(snum)
    snum = input('Enter participant number: ', 's');
end