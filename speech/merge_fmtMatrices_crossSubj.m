function [] = merge_fmtMatrices_crossSubj(exptName,plotfile,conds2merge,mergednames)
%MERGE_FMTMATRICES_CROSSSUBJ  Merges conditions within a plotfile.
%   MERGE_FMTMATRICES_CROSSSUBJ(EXPTNAME,PLOTFILE,CONDS2MERGE,MERGEDNAMES)
%   combines conditions in a plotfile to be plotted as one condition.
%   CONDS2MERGE is an array of cell arrays, each consisting of a pair of
%   condition names (strings). MERGEDNAMES is an array of new condition
%   names for each pair.

dataPath = getAcoustSubjPath(exptName);
load(fullfile(dataPath,plotfile)) % e.g. fmtTraces_3subj.mat
analyses = fieldnames(ffx); %#ok<NODEF>

for a = 1:length(analyses)
    anl = analyses{a};
    for c2m = 1:length(conds2merge)
        oldcnd1 = conds2merge{c2m}{1};
        oldcnd2 = conds2merge{c2m}{2};
        newcnd = mergednames{c2m};
        
        %ffx
        merge1 = ffx.(anl).(oldcnd1);
        merge2 = ffx.(anl).(oldcnd2);
        if size(merge1,1) == size(merge2,1)
            ffx.(anl).(newcnd) = [merge1 merge2];
        else
            ffx.(anl).(newcnd) = merge1;
            for i=1:size(merge2,2)
                ffx.(anl).(newcnd) = nancat(ffx.(anl).(newcnd),merge2(:,i));
            end
        end
        ffx.(anl) = rmfield(ffx.(anl),oldcnd1);
        ffx.(anl) = rmfield(ffx.(anl),oldcnd2);
        
        %rfx
        merge1 = rfx.(anl).(oldcnd1);
        merge2 = rfx.(anl).(oldcnd2);
        if size(merge1,1) == size(merge2,1)
            rfx.(anl).(newcnd) = [merge1 merge2];
        else
            rfx.(anl).(newcnd) = merge1;
            for i=1:size(merge2,2)
                rfx.(anl).(newcnd) = nancat(rfx.(anl).(newcnd),merge2(:,i));
            end
        end
        rfx.(anl) = rmfield(rfx.(anl),oldcnd1);
        rfx.(anl) = rmfield(rfx.(anl),oldcnd2);
    end
end

%% save data
savefile = fullfile(dataPath,sprintf('%s_merged.mat',plotfile));
bSave = savecheck(savefile);
if bSave,
    save(savefile,'ffx','rfx','svec')
end