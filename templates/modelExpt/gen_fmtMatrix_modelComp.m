function [savefile] = gen_fmtMatrix_modelComp(dataPath,dataValsStr,bSaveCheck)
% A wrapper around gen_fmtMatrixByCond designed to be used with data from
% run_modelComp_expt. See gen_fmtMatrixByCond for more info.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(dataValsStr), dataValsStr = 'dataVals_audapter.mat'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end

load(fullfile(dataPath,'expt.mat'),'expt');

conds = {'shiftDown', 'shiftUp'}; 
basecond = 'noShift';
words = expt.words;

colors.shiftDown = [.8 0 0];    % red
colors.shiftUp = [.2 .6 .8];    % blue
colors.noShift = [.5 .5 .5];    % grey

for c=1:length(conds)
    cond = conds{c};
    for w=1:length(words)
        word = words{w};
        shiftnum = (c-1)*length(words) + w;
        
        indShift(shiftnum).name = sprintf('%s%s',cond,word); %#ok<*AGROW> 
        indShift(shiftnum).inds = intersect(expt.inds.conds.(cond),expt.inds.words.(word));
        indShift(shiftnum).shiftind = c;
        indShift(shiftnum).linecolor = colors.(cond);
        
        indBase(shiftnum).name = sprintf('%s%s',basecond,word);
        indBase(shiftnum).inds = intersect(expt.inds.conds.(basecond),expt.inds.words.(word));
        indBase(shiftnum).linecolor = colors.(basecond);
    end
end

savefile = gen_fmtMatrixByCond(dataPath,indBase,indShift,dataValsStr,1,1,bSaveCheck);
