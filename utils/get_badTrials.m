function [badTrials] = get_badTrials(dataPath,dataValsStr)
%GET_BADTRIALS  Get list of bad trials.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end

load(fullfile(dataPath,dataValsStr),'dataVals');
badTrialInds = logical([dataVals.bExcl]);
badTrials = [dataVals(badTrialInds).token];

end
