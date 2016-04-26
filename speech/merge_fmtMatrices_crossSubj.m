function [] = merge_fmtMatrices_crossSubj(exptName,plotfile,conds2merge,mergednames)
%MERGEFMTTRACES Merges conditions within a plotfile.
%   MERGEFMTTRACES_CROSSSUBJ(EXPTNAME,PLOTFILE,CONDS2MERGE,MERGEDNAMES)
%   combines conditions in a plotfile to be plotted as one condition.
%   CONDS2MERGE is an array of cells, each consisting of a pair of
%   condition names (strings). MERGEDNAMES is an array of new condition
%   names for each pair.

dataPath = fullfile(getExptPath,exptName,'acousticdata');
load(fullfile(dataPath,plotfile)) % e.g. fmtTraces_3subj.mat
analyses = fieldnames(ffx); %#ok<NODEF>

for a = 1:length(fns)
    anl = analyses{a};
    for c2m = 1:length(conds2merge)
        %ffx
        merge1 = ffx.(anl).(conds2merge{c2m}{1});
        merge2 = ffx.(anl).(conds2merge{c2m}{2});
        merge1mean = ffx_mean.(anl).(conds2merge{c2m}{1});
        merge2mean = ffx_mean.(anl).(conds2merge{c2m}{2});
        merge1ci = ffx_ci.(anl).(conds2merge{c2m}{1});
        merge2ci = ffx_ci.(anl).(conds2merge{c2m}{2});
        if size(merge1,1) == size(merge2,1)
            ffx.(anl).(mergednames{c2m}) = [merge1 merge2];
            ffx_mean.(anl).(mergednames{c2m}) = nanmean([merge1mean merge2mean],2);
            ffx_ci.(anl).(mergednames{c2m}) = nanmean([merge1ci merge2ci],2);
        else
            ffx.(anl).(mergednames{c2m}) = merge1;
            for i=1:size(merge2,2)
                ffx.(anl).(mergednames{c2m}) = nancat(ffx.(anl).(mergednames{c2m}),merge2(:,i));
            end
            ffx_mean.(anl).(mergednames{c2m}) = nanmean(nancat(merge1mean,merge2mean),2);
            ffx_ci.(anl).(mergednames{c2m}) = nanmean(nancat(merge1ci,merge2ci),2);
        end
        ffx.(anl) = rmfield(ffx.(anl),conds2merge{c2m}{1});
        ffx.(anl) = rmfield(ffx.(anl),conds2merge{c2m}{2});
        ffx_mean.(anl) = rmfield(ffx_mean.(anl),conds2merge{c2m}{1});
        ffx_mean.(anl) = rmfield(ffx_mean.(anl),conds2merge{c2m}{2});
        ffx_ci.(anl) = rmfield(ffx_ci.(anl),conds2merge{c2m}{1});
        ffx_ci.(anl) = rmfield(ffx_ci.(anl),conds2merge{c2m}{2});
        
        %rfx
        merge1 = rfx.(anl).(conds2merge{c2m}{1});
        merge2 = rfx.(anl).(conds2merge{c2m}{2});
        merge1mean = rfx_mean.(anl).(conds2merge{c2m}{1});
        merge2mean = rfx_mean.(anl).(conds2merge{c2m}{2});
        merge1ci = rfx_ci.(anl).(conds2merge{c2m}{1});
        merge2ci = rfx_ci.(anl).(conds2merge{c2m}{2});
        if size(merge1,1) == size(merge2,1)
            rfx.(anl).(mergednames{c2m}) = [merge1 merge2];
            rfx_mean.(anl).(mergednames{c2m}) = nanmean([merge1mean merge2mean],2);
            rfx_ci.(anl).(mergednames{c2m}) = nanmean([merge1ci merge2ci],2);
        else
            rfx.(anl).(mergednames{c2m}) = merge1;
            for i=1:size(merge2,2)
                rfx.(anl).(mergednames{c2m}) = nancat(rfx.(anl).(mergednames{c2m}),merge2(:,i));
            end
            rfx_mean.(anl).(mergednames{c2m}) = nanmean(nancat(merge1mean,merge2mean),2);
            rfx_ci.(anl).(mergednames{c2m}) = nanmean(nancat(merge1ci,merge2ci),2);
        end
        rfx.(anl) = rmfield(rfx.(anl),conds2merge{c2m}{1});
        rfx.(anl) = rmfield(rfx.(anl),conds2merge{c2m}{2});
        rfx_mean.(anl) = rmfield(rfx_mean.(anl),conds2merge{c2m}{1});
        rfx_mean.(anl) = rmfield(rfx_mean.(anl),conds2merge{c2m}{2});
        rfx_ci.(anl) = rmfield(rfx_ci.(anl),conds2merge{c2m}{1});
        rfx_ci.(anl) = rmfield(rfx_ci.(anl),conds2merge{c2m}{2});

    end
end

%% save data
savefile = fullfile(dataPath,sprintf('%s_merged.mat',plotfile));
bSave = savecheck(savefile);
if bSave,
    save(savefile,'ffx','ffx_mean','ffx_ci','rfx','rfx_mean','rfx_ci','svec')
end