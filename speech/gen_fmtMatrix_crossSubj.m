function [ ] = gen_fmtMatrix_crossSubj(exptName,svec,fmtMatrixFile,bSaveCheck)
%GEN_FMTMATRIX_CROSSSUBJ  Generate a plottable fmt matrix across subjects.
%   GEN_FMTMATRIX_CROSSSUBJ(EXPTNAME,SVEC,FMTMATRIXFILE) concatenates
%   formant matrix data from FMTMATRIXFILE for all the subjects in SVEC.
%
% cn 11/2014

if nargin < 2 || isempty(svec)
    exptInfo = get_exptInfo(exptName);
    svec = exptInfo.snums;
    if isfield(exptInfo,'basedir')
        basedir = exptInfo.basedir;
    end
end
if nargin < 3 || isempty(fmtMatrixFile)
    fmtMatrixFile = 'fmtMatrix_EtoIEtoAE_noshift';
end
if nargin < 4 || isempty(bSaveCheck)
    bSaveCheck = 1;
end

if ~exist('basedir','var')
    basedir = getAcoustSubjPath(exptName);
end
if strcmp(exptName,'cat'), subdirname = 'pert/formant_analysis';
elseif strcmp(exptName,'vin'), subdirname = 'all';
elseif strcmp(exptName,'stroop'), subdirname = 'Stroop';
else subdirname = [];
end
ffx = []; rfx = [];

%% concatenate matrices
fprintf('Adding data from subject');
for s=1:length(svec) % for each subject
    % load data
    dataPath = getAcoustSubjPath(exptName,svec(s),subdirname);
    load(fullfile(dataPath,fmtMatrixFile),'fmtMatrix','fmtMeans');
    analyses = fieldnames(fmtMatrix);
    conds = fieldnames(fmtMatrix.diff1);
    
    fprintf(' %d',svec(s));
    for a=1:length(analyses) % for each type of track (diff1, etc.)
        anl = analyses{a};
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

%% save
filesuffix = fmtMatrixFile(11:end);
[~,filesuffix] = fileparts(filesuffix);
filename = sprintf('fmtMatrix_%s_%ds.mat',filesuffix,length(svec));
savefile = fullfile(basedir,filename);
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if bSave,
    save(savefile,'ffx','rfx','svec');
    fprintf('\n%s created.\n',filename);
end