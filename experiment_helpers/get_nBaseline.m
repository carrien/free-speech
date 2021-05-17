function [nBaseline] = get_nBaseline(expt)
% Finds the number of baseline trials in an expt, based on the number of
% consecutive blocks at the beginning of the experiment that only use the
% first condition in expt.conds.
%
% This function was first used for taimComp.
%
% This function assumes that expt.conds{1} is the baseline condition. It
% also assumes the existence and accuracy of:
%   expt.ntrials_per_blocks
%   expt.nblocks
%   expt.conds
%
% v1, CWN 2021-03


nConds = length(expt.conds);

if nConds == 1
    %warning('Function only works for expts with multiple conds.')
    nBaseline = 0;
    return;
end

for iBlock = 1:expt.nblocks
    first = 1 + ((iBlock-1) * expt.ntrials_per_block);
    last = iBlock * expt.ntrials_per_block;
    if any(1 ~= expt.allConds(first:last))
        nBaseline = (iBlock-1) * expt.ntrials_per_block;
        return;
    end
end

% This happens if you have multiple conds, but are only using 1
if ~exist('nBaseline', 'var')
    nBaseline = 0;
end


end