function [badTrials] = get_badTrials(dataPath)
%GET_BADTRIALS  Get list of bad trials.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

load(fullfile(dataPath,'dataVals.mat'));
badTrials = find([dataVals.bExcl]);

end

