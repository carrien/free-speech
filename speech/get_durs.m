function [allDurs] = get_durs(dataPaths,dataValsStr,trackname)

if nargin < 2 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end
if nargin < 3 || isempty(trackname), trackname = 'f0'; end
allDurs = [];

for dP = 1:length(dataPaths)
    dataPath = dataPaths{dP};
    load(fullfile(dataPath,dataValsStr),'dataVals');
    if isfield(dataVals,'dur')
        durs = [dataVals.dur];
    else
        for j = 1:length(dataVals)
            durs(j) = dataVals(j).(trackname)(end,1)-dataVals(j).(trackname)(1,1);
        end
    end
    allDurs = nancat(allDurs,durs');
    clear durs
end