function [nExcl,nTrials] = get_nExcludedTrials(dataPaths,dataValsStr)
%GET_NEXCLUDEDTRIALS  Get the number of excluded trials per subject.

if nargin < 1 || isempty(dataPaths), dataPaths = {cd}; end
if nargin < 2 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end

nSubj = length(dataPaths);
nTrials = zeros(1,nSubj);
nExcl = zeros(1,nSubj);
for dP = 1:nSubj
    dataPath = dataPaths{dP};
    load(fullfile(dataPath,dataValsStr),'dataVals')
    nTrials(dP) = length(dataVals);
    nExcl(dP) = sum([dataVals.bExcl]);
end
