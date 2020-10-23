function [rp] = get_matchingPermutationOrder(allConds,condbank)
% Return permutation index that would permute condbank into allConds.

if nargin < 2, condbank = sort(allConds); end

conds = unique(allConds);
rp = zeros(1,length(condbank));

for c = 1:length(conds)
    inds = allConds == conds(c);
    bankinds = find(condbank == conds(c));
    len = sum(inds);
    rl = randperm(len);
    rp(inds) = bankinds(rl);
end