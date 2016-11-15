function [] = merge_fmtMatrices(exptName,snum,plotfile,conds2merge,mergednames)
%MERGE_FMTMATRICES  Merges conditions within a plotfile.
%   MERGE_FMTMATRICES(EXPTNAME,SNUM,PLOTFILE,CONDS2MERGE,MERGEDNAMES)
%   combines conditions in a plotfile to be plotted as one condition.
%   CONDS2MERGE is an array of cell arrays, each consisting of a pair of
%   condition names (strings). MERGEDNAMES is an array of new condition
%   names for each pair.

dataPath = getAcoustSubjPath(exptName,snum);
load(fullfile(dataPath,plotfile),'fmtMatrix','fmtMeans','tstep','bMels','bFilt') % e.g. fmtTraces_3subj.mat
analyses = fieldnames(fmtMeans); %#ok<NODEF>

for c2m = 1:length(conds2merge)
    oldcnd1 = conds2merge{c2m}{1};
    oldcnd2 = conds2merge{c2m}{2};
    newcnd = mergednames{c2m};
    
    for a = 1:length(analyses)
        anl = analyses{a};
        
        % fmtMatrix (all trials: ffx)
        merge1 = fmtMatrix.(anl).(oldcnd1);
        merge2 = fmtMatrix.(anl).(oldcnd2);
        if size(merge1,1) == size(merge2,1)
            fmtMatrix.(anl).(newcnd) = [merge1 merge2];
        else
            fmtMatrix.(anl).(newcnd) = merge1;
            for i=1:size(merge2,2)
                fmtMatrix.(anl).(newcnd) = nancat(fmtMatrix.(anl).(newcnd),merge2(:,i));
            end
        end
        fmtMatrix.(anl) = rmfield(fmtMatrix.(anl),oldcnd1);
        fmtMatrix.(anl) = rmfield(fmtMatrix.(anl),oldcnd2);
        
        % fmtMeans (one average trial: rfx)
        merge1 = fmtMeans.(anl).(oldcnd1);
        merge2 = fmtMeans.(anl).(oldcnd2);
        if size(merge1,1) == size(merge2,1)
            fmtMeans.(anl).(newcnd) = [merge1 merge2];
        else
            fmtMeans.(anl).(newcnd) = merge1;
            for i=1:size(merge2,2)
                fmtMeans.(anl).(newcnd) = nancat(fmtMeans.(anl).(newcnd),merge2(:,i));
            end
        end
        fmtMeans.(anl) = rmfield(fmtMeans.(anl),oldcnd1);
        fmtMeans.(anl) = rmfield(fmtMeans.(anl),oldcnd2);
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