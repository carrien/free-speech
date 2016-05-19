function [] = gen_fmtMatrixByCond(exptName,snum,indBase,indShift,dataValsStr,bMels,bFilt,bSaveCheck)
%GEN_FMTMATRIXBYCOND  Generate a plottable formant matrix from a davaVals object.
%   GEN_FMTMATRIXBYCOND(EXPTNAME,SNUM,DATAVALS,INDBASE,INDSHIFT,BFILT)
%   Generates a fmtMatrix suitable for plotting by, e.g. plotFmtTraces_x.
%   INDBASE and INDSHIFT are cell arrays containing the indices of the
%   baseline and shift for each condition.  (If the baseline indices are
%   the same for all conditions, INDBASE may be a cell array of length 1
%   with a single copy of these indices.)

if nargin < 5 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end
if nargin < 6 || isempty(bMels), bMels = 1; end % binary variable: convert to mels or don't
if nargin < 7 || isempty(bFilt), bFilt = 1; end % binary variable: filt on or off
if nargin < 8 || isempty(bSaveCheck), bSaveCheck = 1; end
if strcmp(exptName,'cat')
    subdirname = 'pert/formant_analysis';
elseif strcmp(exptName,'mvSIS') || strcmp(exptName,'mpSIS')
    subdirname = 'speak';
elseif strcmp(exptName,'vin')
    subdirname = 'all';
else
    subdirname = [];
end

% match baselines to number of conditions
conds = {indShift.name};
if length(indBase) ~= length(conds)
    if length(indBase) == 1
        basename = indBase(1).name;
        for c=2:length(conds)
            indBase(c) = indBase(1);
        end
    else error('Number of baselines must match number of conditions to plot.')
    end
else basename = [indBase.name];
end
baseconds = {indBase.name};

dataPath = getAcoustSubjPath(exptName,snum,subdirname);
load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,dataValsStr));

%% generate traces (each with its own baseline)
display(sprintf('Subject %.0f',snum));
for c = 1:length(indShift) % for each condition to plot
    %% generate array of baseline traces (each column is a trial)
    if indBase(c).inds == 0 % if no baseline -- not well-tested
        rawf1.(baseconds{c}) = 0;
        rawf2.(baseconds{c}) = 0;
    else % generate matrix for THIS (cond-specific) baseline
        [rawf1.(baseconds{c}),rawf2.(baseconds{c})] = get_fmtMatrix(dataVals,indBase(c).inds,bMels,bFilt);
    end
    % get mean baseline
    rawf1_mean.(baseconds{c}) = nanmean(rawf1.(baseconds{c}),2); % mean formants for shift-specific baseline
    rawf2_mean.(baseconds{c}) = nanmean(rawf2.(baseconds{c}),2); %
    
    %% generate array of shifted traces
    if indShift(c).inds
        % generate matrix for this cond
        [rawf1.(conds{c}),rawf2.(conds{c})] = get_fmtMatrix(dataVals,indShift(c).inds,bMels,bFilt);
        % get mean of this cond
        rawf1_mean.(conds{c}) = nanmean(rawf1.(conds{c}),2);
        rawf2_mean.(conds{c}) = nanmean(rawf2.(conds{c}),2);
        
        % generate difference matrix for this cond (subtract mean baseline)
        nSamplesLongestTrial = size(rawf1.(conds{c}),1);
        ntrialsPerThisCond = size(rawf1.(conds{c}),2);
        % tile mean baseline trace, one copy per trial in this cond
        tiledMeanBaseF1 = repmat(rawf1_mean.(baseconds{c}),1,ntrialsPerThisCond); 
        tiledMeanBaseF2 = repmat(rawf2_mean.(baseconds{c}),1,ntrialsPerThisCond);
        % trim tiledbase and cond traces to same length (nsamples)
        if size(tiledMeanBaseF1,1) > nSamplesLongestTrial
            tiledMeanBaseF1 = tiledMeanBaseF1(1:nSamplesLongestTrial,:);
            tiledMeanBaseF2 = tiledMeanBaseF2(1:nSamplesLongestTrial,:);
            tiledRawF1 = rawf1.(conds{c});
            tiledRawF2 = rawf2.(conds{c});
        elseif size(tiledMeanBaseF1,1) <= nSamplesLongestTrial
            tiledRawF1 = rawf1.(conds{c})(1:size(tiledMeanBaseF1,1),:);
            tiledRawF2 = rawf2.(conds{c})(1:size(tiledMeanBaseF2,1),:);
        end
        % subtract mean cond-specific baseline for each trial
        diff1.(conds{c}) = tiledRawF1-tiledMeanBaseF1;
        diff2.(conds{c}) = tiledRawF2-tiledMeanBaseF2;
        
        % generate difference vector for this cond (subtract mean baseline from mean cond)
        [a,b] = samelen(rawf1_mean.(conds{c}),rawf1_mean.(baseconds{c}));
        diff1_mean.(conds{c}) = a-b;
        [a,b] = samelen(rawf2_mean.(conds{c}),rawf2_mean.(baseconds{c}));
        diff2_mean.(conds{c}) = a-b;        
        diff2d.(conds{c}) = sqrt(diff1.(conds{c}).^2 + diff2.(conds{c}).^2);
        diff2d_mean.(conds{c}) = sqrt(diff1_mean.(conds{c}).^2 + diff2_mean.(conds{c}).^2);
        
        % calculate trial ending points
        hashalf.(conds{c}) = zeros(size(diff1.(conds{c}),1),1); % hashalf = 1 at each timepoint with fewer than half of trials NaN
        hasthird.(conds{c}) = zeros(size(diff1.(conds{c}),1),1);
        hasquart.(conds{c}) = zeros(size(diff1.(conds{c}),1),1);
        for t = 1:size(diff1.(conds{c}),1) % for each timepoint
            dif1 = diff1.(conds{c})(t,:); dif1 = dif1(~isnan(dif1)); % remove NaNs
            if length(dif1)>length(diff1.(conds{c})(t,:))/2,hashalf.(conds{c})(t) = 1;end
            if length(dif1)>length(diff1.(conds{c})(t,:))/3,hasthird.(conds{c})(t) = 1;end
            if length(dif1)>length(diff1.(conds{c})(t,:))/4,hasquart.(conds{c})(t) = 1;end
        end
        
        %% if a perturbation study
        if isfield(indShift,'shiftind')
            % get shift vector
            if bMels
                shiftvec = expt.shifts.mels{indShift(c).shiftind};
            else
                if isfield(expt.shifts,'true_hz'),
                    fprintf('Warning: field "true_hz" found; using these values for shiftvec.\n')
                    shiftvec = expt.shifts.true_hz{indShift(c).shiftind};
                else
                    shiftvec = expt.shifts.hz{indShift(c).shiftind};
                end
            end
            magShift = sqrt(shiftvec(1)^2 + shiftvec(2)^2);
            %display(sprintf('%s magShift = %2f; sdist = %2f',conds{c},magShift,subjInfo.sdist))
            
            % get percentage differences
            percdiff1.(conds{c}) = diff1.(conds{c}).*(100/shiftvec(1));
            percdiff1_mean.(conds{c}) = diff1_mean.(conds{c}).*(100/abs(shiftvec(1)));
            percdiff2.(conds{c}) = diff2.(conds{c}).*(100/shiftvec(2));
            percdiff2_mean.(conds{c}) = diff2_mean.(conds{c}).*(100/abs(shiftvec(2)));
            percdiff2d.(conds{c}) = diff2d.(conds{c}).*(100/magShift);
            percdiff2d_mean.(conds{c}) = diff2d_mean.(conds{c}).*(100/magShift);
            
            % calculate dot products (projection and efficiency)
            display(sprintf('Calculating dot products: %s',conds{c}))
            for t = 1:size(diff1.(conds{c}),1) % for each timepoint
                proj_mean.(conds{c})(t,1) = dot([diff1_mean.(conds{c})(t) diff2_mean.(conds{c})(t)],-shiftvec)/magShift;
                effproj_mean.(conds{c})(t,1) = proj_mean.(conds{c})(t)*(100/diff2d_mean.(conds{c})(t));
                effdist_mean.(conds{c})(t,1) = diff2d_mean.(conds{c})(t) - proj_mean.(conds{c})(t);
                for trial = 1:size(diff1.(conds{c}),2) % for each trial
                    proj.(conds{c})(t,trial) = dot([diff1.(conds{c})(t,trial) diff2.(conds{c})(t,trial)],-shiftvec)/magShift;
                    effproj.(conds{c})(t,trial) = proj.(conds{c})(t,trial)*(100/diff2d.(conds{c})(t,trial));
                    effdist.(conds{c})(t,trial) = diff2d.(conds{c})(t,trial) - proj.(conds{c})(t,trial);
                end
            end
            percproj.(conds{c}) = proj.(conds{c}).*(100/magShift);
            percproj_mean.(conds{c}) = proj_mean.(conds{c}).*(100/magShift);
        end
        
    end
end

tstep = unique(diff(dataVals(1).ftrack_taxis)); %#ok<NASGU>

%% save data
filename = sprintf('fmtMatrix_%s_%s.mat',[indShift.name],basename);
if length(filename) > 100
    filename = 'fmtMatrix_singletrial_25closest';
    fprintf('Warning: Changing filename to %s.mat!\n',filename)
    pause(1)
end

savefile = fullfile(dataPath,filename);
fmtMatrix.rawf1 = rawf1; fmtMeans.rawf1 = rawf1_mean;
fmtMatrix.rawf2 = rawf2; fmtMeans.rawf2 = rawf2_mean;
fmtMatrix.diff1 = diff1; fmtMeans.diff1 = diff1_mean;
fmtMatrix.diff2 = diff2; fmtMeans.diff2 = diff2_mean;
fmtMatrix.diff2d = diff2d; fmtMeans.diff2d = diff2d_mean;
if isfield(indShift,'shiftind')
    fmtMatrix.percdiff1 = percdiff1; fmtMeans.percdiff1 = percdiff1_mean;
    fmtMatrix.percdiff2 = percdiff2; fmtMeans.percdiff2 = percdiff2_mean;
    fmtMatrix.percdiff2d = percdiff2d; fmtMeans.percdiff2d = percdiff2d_mean;
    fmtMatrix.proj = proj; fmtMeans.proj = proj_mean;
    fmtMatrix.percproj = percproj; fmtMeans.percproj = percproj_mean;
    fmtMatrix.effproj = effproj; fmtMeans.effproj = effproj_mean;
    fmtMatrix.effdist = effdist; fmtMeans.effdist = effdist_mean; %#ok<STRNU>
end

if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if bSave
    save(savefile,'fmtMatrix','fmtMeans','hashalf','hasthird','hasquart','tstep','bMels','bFilt')
    fprintf('%s created.\n',filename);
end