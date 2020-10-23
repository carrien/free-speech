function [missingTrialPercent] = calc_missingTrialN(dataPaths,subpaths)
%for a given experiment, calculate the percentage of trials excluded
%(~bGoodTrial) for each paricipant.

if nargin < 1 || isempty(dataPaths)
    error('No dataPaths given')
end
if nargin < 2 || isempty(subpaths)
    nSubpaths = 0;
else
    nSubpaths = length(subpaths);
end

nPaths = length(dataPaths);

missingTrialPercent = [];
for dP = 1:nPaths
    if nSubpaths > 0
        for s = 1:nSubpaths
            dataPath = fullfile(dataPaths{dP},subpaths{s});
            missingTrialPercent(end+1) = loadAndCalc(dataPath);
        end
    else
        dataPath = dataPaths{dP};
        missingTrialPercent(end+1) = loadAndCalc(dataPath);
    end
end

end

function mP = loadAndCalc(dataPath)
    fprintf('Analyzing %s\n',dataPath)
    load(fullfile(dataPath,'dataVals.mat'))
    mP = sum([dataVals(:).bExcl]==1)./length(dataVals);
    clear dataVals
end