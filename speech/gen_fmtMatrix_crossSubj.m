function [ ] = gen_fmtMatrix_crossSubj(exptName,svec,fmtMatrixFile,bSaveCheck)
%GEN_FMTMATRIX_CROSSSUBJ  Generate a plottable fmt matrix across subjects.
%   GEN_FMTMATRIX_CROSSSUBJ(EXPTNAME,SVEC,FMTMATRIXFILE) concatenates
%   formant matrix data from FMTMATRIXFILE for all the subjects in SVEC,
%   which can be a vector of subject numbers or a cell array of subject ID
%   strings.
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
    basedir = get_acoustLoadPath(exptName);
end
switch exptName
    case 'cat'
        subdirname = 'pert/formant_analysis';
    case 'vin'
        subdirname = 'all';
    case 'stroop'
        subdirname = 'Stroop';
    otherwise
        subdirname = [];
end
if isnumeric(svec)
    sids = cell(1,length(svec));
    for s=1:length(svec)
        sids{s} = sprintf('s%02d',svec(s));
    end
else
    sids = svec;
end
ffx = []; rfx = [];

%% concatenate matrices
fprintf('Adding data from subject');
for s=1:length(sids) % for each subject
    % load data
    dataPath = get_acoustLoadPath(exptName,sids{s},subdirname);
    load(fullfile(dataPath,fmtMatrixFile));
    analyses = fieldnames(fmtMatrix);
    bMelsVec(s) = bMels;
    bFiltVec(s) = bFilt;
    
    fprintf(' %s',sids{s});
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
    warning('Inconsistant frequency scale: the following subjects'' data are in mels: %s',sids{logical(bMelsVec)})
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
if bSave
    save(savefile,'ffx','rfx','svec','sids','tstep','bMels','bFilt');
    if exist('linecolors','var')
        save(savefile,'linecolors','-append')
    end    
    fprintf('\n%s created.\n',filename);
end