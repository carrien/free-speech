function [ ] = gen_fmtMatrix_crossSubj(dataPaths,fmtMatrixFile,outputdir,bSaveCheck)
%GEN_FMTMATRIX_CROSSSUBJ  Generate plottable fmt matrix across subjects.
%   GEN_FMTMATRIX_CROSSSUBJ(DATAPATHS,FMTMATRIXFILE,BSAVECHECK)
%   concatenates formant matrix data from FMTMATRIXFILE for all paths in
%   DATAPATHS. BSAVECHECK = 1 prompts before overwriting an existing file.
%
% cn 11/2014

if nargin < 3 || isempty(outputdir), outputdir = uigetdir; end
if ~outputdir, return; end
if nargin < 4 || isempty(bSaveCheck), bSaveCheck = 1; end

%% construct output filename
fileprefix = 'fmtMatrix_';
filesuffix = fmtMatrixFile(length(fileprefix)+1:end);
[~,filesuffix] = fileparts(filesuffix);
filename = sprintf('fmtMatrix_%s_%ds.mat',filesuffix,length(dataPaths));
savefile = fullfile(outputdir,filename);

if bSaveCheck % check for existing file
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if ~bSave
    fprintf('Not saved.\n');
    return;
end

ffx = []; rfx = [];

%% concatenate matrices
fprintf('Adding data from folder');
for dP=1:length(dataPaths) % for each subject
    % load data
    dataPath = dataPaths{dP};
    load(fullfile(dataPath,fmtMatrixFile));
    analyses = fieldnames(fmtMatrix);
    bMelsVec(dP) = bMels;
    bFiltVec(dP) = bFilt;
    
    fprintf(' %d',dP);
    for a=1:length(analyses) % for each type of track (diff1, etc.)
        anl = analyses{a};
        conds = fieldnames(fmtMatrix.(anl));
        for c=1:length(conds) % for each shift condition
            cnd = conds{c};

            % concat all trials (fixed effects)
            if ~isfield(ffx,anl) || ~isfield(ffx.(anl),cnd)
                ffx.(anl).(cnd) = fmtMatrix.(anl).(cnd);
            else
                for trial = 1:size(fmtMatrix.(anl).(cnd),2) % for each trial
                    sig = fmtMatrix.(anl).(cnd)(:,trial);
                    ffx.(anl).(cnd) = nancat(ffx.(anl).(cnd),sig);
                end
            end
            
            % concat only means (random effects)
            if ~isfield(rfx,anl) || ~isfield(rfx.(anl),cnd)
                rfx.(anl).(cnd) = fmtMeans.(anl).(cnd);
            else
                rfx.(anl).(cnd) = nancat(rfx.(anl).(cnd),fmtMeans.(anl).(cnd));
            end
            
        end
    end
end

bMels = unique(bMelsVec);
bFilt = unique(bFiltVec);
if length(bMels) > 1
    warning('Inconsistant frequency scale:\nData from the following folders are in mels:\n%s',dataPaths{logical(bMelsVec)})
end

%% save
save(savefile,'ffx','rfx','dataPaths','tstep','bMels','bFilt');
if exist('linecolors','var')
    save(savefile,'linecolors','-append')
end
fprintf('\n%s created.\n',filename);
