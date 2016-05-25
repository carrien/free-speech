function [expt] = merge_exptFiles(dataPaths,savePath,elements)
%MERGE_EXPTFILES  Merges multiple experiment info files.
%   MERGE_EXPTFILES(DATAPATHS,SAVEPATH) loops through the directories in
%   DATAPATHS and generates an expt.mat file merging the info in all of
%   them, saved in SAVEPATH. ELEMENTS is a cell array of strings denoting
%   the elements of the experiment whose info is saved in expt, e.g. conds,
%   words, vowels, tones, colors, etc.

if nargin < 2, savePath = pwd; end
if nargin < 3, elements = {'conds' 'words' 'vowels'}; end

for i=1:length(dataPaths)
    exptpart = load(fullfile(dataPaths{i},'expt'));
    exptpart = exptpart.expt;
    if ~exist('expt','var')
        expt = exptpart;
    else
        % check that experiment name and subject number match
        if ~strcmp(expt.name,exptpart.name)
            error('Experiment names do not match: merging failed.');
        elseif ischar(expt.snum) && ~strcmp(expt.snum,exptpart.snum) || ...
                isnumeric(expt.snum) && expt.snum~=exptpart.snum
            error('Subject numbers do not match: merging failed.');
        end
        % check that conditions, words, and vowels match
        % (otherwise indices don't refer to same elements)
        for e=1:length(elements)
            el = elements{e};
            if ~all(strcmp(expt.(el),exptpart.(el)))
                error('Experiment %s do not match: merging failed.',el)
            end
        end
        % sum trials
        expt.ntrials = expt.ntrials + exptpart.ntrials;
        expt.nblocks = expt.nblocks + exptpart.nblocks;
        % merge all remaining fields (except inds)
        exptpart = rmfield(exptpart,{'name','snum','dataPath','ntrials','nblocks','nbtrials','inds'});
        exptpart = rmfield(exptpart,elements);
        fns = fieldnames(exptpart);
        for fn=1:length(fns)
            data2add = exptpart.(fns{fn});
            expt.(fns{fn}) = horzcat(expt.(fns{fn}),data2add);
        end
    end
end

% recalculate indices
expt.inds = get_exptInds(expt,elements);

% update dataPath
expt.dataPath = savePath;

if ~exist(savePath,'dir')
    mkdir(savePath)
end
savefile = fullfile(savePath,'expt.mat');
bSave = savecheck(savefile);
if bSave
    save(savefile, 'expt');
end
