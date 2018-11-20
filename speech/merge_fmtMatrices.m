function [] = merge_fmtMatrices(exptName,snum,plotfile,conds2merge,mergednames)
%MERGE_FMTMATRICES  Merges conditions within a plotfile.
%   MERGE_FMTMATRICES(EXPTNAME,SNUM,PLOTFILE,CONDS2MERGE,MERGEDNAMES)
%   combines conditions in a plotfile to be plotted as one condition.
%   CONDS2MERGE is an array of cell arrays, each consisting of a pair of
%   condition names (strings). MERGEDNAMES is an array of new condition
%   names for each pair.

% dataPath = getAcoustSubjPath(exptName,snum); %BP note: this function is
% currently broken as of 11/20/2018
dataPath = pwd;
load(fullfile(dataPath,plotfile),'fmtMatrix','fmtMeans','tstep','bMels','bFilt') % e.g. fmtTraces_3subj.mat
analyses = fieldnames(fmtMeans); %#ok<NODEF>

for c2m = 1:length(conds2merge)
    nSubConds = length(conds2merge{c2m});
    for iSubConds = 1:nSubConds
        oldcnd{iSubConds} = conds2merge{c2m}{iSubConds};
    end
    
    newcnd = mergednames{c2m};
    
    for a = 1:length(analyses)
        anl = analyses{a};
        
        % fmtMatrix (all trials: ffx)
        for iSubConds = 1:nSubConds
            merge{iSubConds} = fmtMatrix.(anl).(oldcnd{iSubConds});
        end

        fmtMatrix.(anl).(newcnd) = merge{1};
        for iSubConds=2:nSubConds
            fmtMatrix.(anl).(newcnd) = nancat(fmtMatrix.(anl).(newcnd),merge{iSubConds});
        end
    
        for iSubConds=1:nSubConds
            fmtMatrix.(anl) = rmfield(fmtMatrix.(anl),oldcnd{iSubConds});
        end
        
        % fmtMeans (one average trial: rfx)
        for iSubConds = 1:nSubConds
            merge{iSubConds} = fmtMeans.(anl).(oldcnd{iSubConds});
        end

        fmtMeans.(anl).(newcnd) = merge{1};
        for iSubConds=2:nSubConds
            fmtMeans.(anl).(newcnd) = nancat(fmtMeans.(anl).(newcnd),merge{iSubConds});
        end
        fmtMeans.(anl).(newcnd) = nanmean(fmtMeans.(anl).(newcnd),2);

        for iSubConds=1:nSubConds
            fmtMeans.(anl) = rmfield(fmtMeans.(anl),oldcnd{iSubConds});
        end

    end
    
    % hasNpercent
    hashalf.(newcnd) = has_nperc(fmtMatrix.diff1.(newcnd),50);
    hasthird.(newcnd) = has_nperc(fmtMatrix.diff1.(newcnd),33.3333);
    hasquart.(newcnd) = has_nperc(fmtMatrix.diff1.(newcnd),25);
end

%% save data
if bMels, bMelsStr = '_mels'; else bMelsStr = []; end
savefile = fullfile(dataPath,sprintf('fmtMatrix_%s_merged%s.mat',cell2mat(mergednames),bMelsStr));
bSave = savecheck(savefile);
if bSave,
    save(savefile,'fmtMatrix','fmtMeans','hashalf','hasthird','hasquart','tstep','bMels','bFilt')
end