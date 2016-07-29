function [] = gen_fmtMatrixAllCondsNoBaseline(exptName,snum,dataValsStr,bSaveCheck)

if nargin < 3 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end
if nargin < 4 || isempty(bSaveCheck), bSaveCheck = 1; end

dataPath = getAcoustSubjPath(exptName,snum,'all');
load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,dataValsStr));

condnames = expt.conds;
condlist = [dataVals.cond];
inds2excl = [dataVals.bExcl];

for c = 1:length(condnames)
    indBase(c).name = condnames{c};
    indBase(c).inds = setdiff(find(condlist == c),inds2excl);
    indCond(c).name = condnames{c};
    indCond(c).inds = setdiff(find(condlist == c),inds2excl);
end
    
bMels = 1;
bFilt = 1;

gen_fmtMatrixByCond(dataPath,indBase,indCond,dataValsStr,bMels,bFilt,bSaveCheck)