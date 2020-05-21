function [compensation,se,bSigComp] = get_compensationBySubj(dataPaths,params)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2 || isempty(params), params = struct; end

% set defaults
defaults.startTimeMs = .2;
defaults.endTimeMs = .3;
defaults.endTimeBaseMs = .1;
defaults.measSel = 'diff1';
defaults.shift2use = 'all';
defaults.fmtMatrixFilename = 'fmtMatrix_shiftUpshiftDown_merged';
defaults.byTrialMeans = 0; % 0 = create an average response trial first, then average within a window; 1 = average within window for each trial, then average across trials
params = set_missingFields(params,defaults,0);
measSel = params.measSel;

nSubs = length(dataPaths);
compensation = nan(1,nSubs);
se = nan(1,nSubs);
bSigComp = nan(1,nSubs);

for s = 1:nSubs
    
    % get data and time axis
    dataPath = dataPaths{s};
    if exist(fullfile(dataPath,[params.fmtMatrixFilename '.mat']),'file')
        load(fullfile(dataPath,params.fmtMatrixFilename),'fmtMatrix');
        if ~exist('tstep','var')
            load(fullfile(dataPath,'dataVals.mat'),'dataVals');
            goodtrials = find(~[dataVals.bExcl]);
            tstep = mean(diff(dataVals(goodtrials(1)).ftrack_taxis));
        end

        % set time windows
        startTime = floor(params.startTimeMs/tstep);
        endTime = floor(params.endTimeMs/tstep);
        maxEndTime = min([size(fmtMatrix.(measSel).shiftUp,1) size(fmtMatrix.(measSel).shiftDown,1)]);
        %maxEndTime = min([find(percNaN.shiftUp <= 50, 1, 'last') find(percNaN.shiftDown <= 50, 1, 'last')]);
        endTime = min(endTime,maxEndTime);

        % get average compensation in time window
        if params.byTrialMeans
            trialMeansUp = -1.*nanmedian(fmtMatrix.(measSel).shiftUp(startTime:endTime,:));
            trialMeansDown = nanmedian(fmtMatrix.(measSel).shiftDown(startTime:endTime,:));
        else
            trialMeansUp = -1.*nanmedian(fmtMatrix.(measSel).shiftUp(startTime:endTime,:),2);
            trialMeansDown = nanmedian(fmtMatrix.(measSel).shiftDown(startTime:endTime,:),2);
        end

        switch params.shift2use
            case 'up'
                trialMeans = trialMeansUp;
            case 'down'
                trialMeans = trialMeansDown;
            case 'all'
                if params.byTrialMeans
                    trialMeans = [trialMeansUp trialMeansDown];
                else
                    trialMeans = nanmean([trialMeansUp trialMeansDown],2);
                end
        end
        compensation(s) = nanmean(trialMeans);
        bSigComp(s) = ttest(trialMeans,0,'Tail','both');
        if params.byTrialMeans
            se(s) = get_errorbars(trialMeans,'se');
        end
        clear trialMeans
    else
        warning(sprintf('No fmtMatrix file found for participant %d. Returning NaN values for this participant',s))
        compensation(s) = nanmean(NaN);
        bSigComp(s) = NaN;
    end
end
