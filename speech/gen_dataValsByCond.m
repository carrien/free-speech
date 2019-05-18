function [ ] = gen_dataValsByCond(dataPath,grouping)
%GEN_DATAVALSBYCOND  Generate dataVals subsets.
%   GEN_DATAVALSBYCOND(DATAPATH,GROUPING) generates a separate dataVals
%   file for each condition in GROUPING (e.g. words, colors, etc.)

load(fullfile(dataPath,'expt.mat'),'expt');
load(fullfile(dataPath,'dataVals.mat'),'dataVals');
dataValsAll = dataVals;

conds = expt.(grouping);

for c=1:length(conds)
    condname = conds{c};
    inds = expt.inds.(grouping).(condname);
    dataVals = dataValsAll(inds);
    
    saveFile = fullfile(dataPath,sprintf('dataVals_%s',condname));
    save(saveFile,'dataVals');
    fprintf('%s dataVals saved to %s\n',condname,saveFile);
end

