function [] = merge_fmtMatrices(dataPath,plotfile,conds2merge,mergednames,bSaveCheck)
%MERGE_FMTMATRICES  Merges conditions within a plotfile.
%   MERGE_FMTMATRICES(DATAPATH,PLOTFILE,CONDS2MERGE,MERGEDNAMES) combines
%   conditions in a plotfile to be plotted as one condition. CONDS2MERGE is
%   an array of cell arrays, each consisting of a pair of condition names
%   (strings). MERGEDNAMES is an array of new condition names for each
%   pair.
if nargin < 5 || isempty(bSaveCheck)
    bSaveCheck = 1;
end

fmtData = load(fullfile(dataPath,plotfile)); % e.g. fmtMatrix_shiftUpshiftDown_noShift.mat
fmtMatrix = fmtData.fmtMatrix;
fmtMeans = fmtData.fmtMeans;
analyses = fieldnames(fmtMeans);

for c2m = 1:length(conds2merge)
    nSubConds = length(conds2merge{c2m});
    for iSubConds = 1:nSubConds
        oldcnd{iSubConds} = conds2merge{c2m}{iSubConds};
    end
    
    newcnd = mergednames{c2m};
    
    for a = 1:length(analyses)
        anl = analyses{a};
        
        % fmtMatrix (all trials: ffx)
        fmtMatrix.(anl).(newcnd) = [];
        for iSubConds=1:nSubConds
            data2add = fmtMatrix.(anl).(oldcnd{iSubConds});
            fmtMatrix.(anl).(newcnd) = nancat(fmtMatrix.(anl).(newcnd),data2add);
            fmtMatrix.(anl) = rmfield(fmtMatrix.(anl),oldcnd{iSubConds});
        end
        
        % fmtMeans (one average trial: rfx)
        fmtMeans.(anl).(newcnd) = [];
        for iSubConds=1:nSubConds
            data2add = fmtMeans.(anl).(oldcnd{iSubConds});
            fmtMeans.(anl).(newcnd) = nancat(fmtMeans.(anl).(newcnd),data2add);
            fmtMeans.(anl) = rmfield(fmtMeans.(anl),oldcnd{iSubConds});
        end
        fmtMeans.(anl).(newcnd) = nanmean(fmtMeans.(anl).(newcnd),2); %%

    end
    
    % recalculate trial ending points
    fmtData.percNaN.(newcnd) = get_percNaN(fmtMatrix.diff1.(newcnd));

    % linecolors
    if isfield(fmtData,'linecolors') && isstruct(fmtData.linecolors)
        for iCond=1:length(mergednames)
            fmtData.linecolors.(mergednames{iCond}) = fmtData.linecolors.(conds2merge{iCond}{1});
        end
    end
        
end

%% save data
fmtData.fmtMatrix = fmtMatrix;
fmtData.fmtMeans = fmtMeans;

savefile = fullfile(dataPath,sprintf('fmtMatrix_%s_merged.mat',cell2mat(mergednames)));
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end

if bSave
    save(savefile,'-struct','fmtData')
    fprintf('%s created.\n',savefile);
end
