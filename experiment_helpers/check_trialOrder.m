function [bTrialOrderOK] = check_trialOrder(allConds,shiftConds,constraints)
%CHECK_TRIALORDER  Check if trial order meets experiment constraints.
%   CHECK_TRIALORDER(ALLCONDS,SHIFTINDS,CONSTRAINTS) ALLCONDS is a list of
%   all conditions, SHIFTINDS is a list of indices corresponding to
%   feedback shifts in the ALLCONDS list, and CONSTRAINTS is a cell array
%   of strings denoting which constraints should be applied:
%        no2same  : No two consecutive shifts of the same kind
%        no2shift : No two consecutive shifts of any kind
%        etc.

if nargin < 3, constraints = {'no2same'}; end

bTrialOrderOK = 1;

% No two consecutive shifts of the same kind
if any(strcmp(constraints,'no2same'))
    for s = shiftConds
        inds = find(allConds == s);
        if any(diff(inds) == 1)
            bTrialOrderOK = 0;
            return;
        end
    end
end

% No two consecutive shifts of any kind
if any(strcmp(constraints,'no2shift'))
    for t = 1:length(allConds)-1
        if any(allConds(t) == shiftConds) && any(allConds(t+1) == shiftConds)
            bTrialOrderOK = 0;
            return;
        end
    end
end
