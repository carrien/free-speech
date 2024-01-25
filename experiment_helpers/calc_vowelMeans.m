function [fmtMeans, fmtStds, fmtMedians, TargetIx] = calc_vowelMeans(dataPath,conds2analyze,bRmOutliers,ostInds,bTest)
%CALC_VOWELMEANS  Calculates mean vowel formants from Audapter OST data.
%   FMTMEANS = CALC_VOWELMEANS(DATAPATH) calculates mean formants for each
%   vowel in an Audapter experiment. DATAPATH is the path to a folder
%   containing data.mat (Audapter output data) and expt.mat (experiment
%   metadata) files. OSTINDS is the desired OST status to track.

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
load(fullfile(dataPath,'expt.mat'),'expt');
load(fullfile(dataPath,'data.mat'),'data');
if nargin < 2 || isempty(conds2analyze), conds2analyze = expt.conds; end
if nargin < 3 || isempty(bRmOutliers), bRmOutliers = 1; end
if nargin < 4 || isempty(ostInds), ostInds = 2; end
if nargin < 5 || isempty (bTest), bTest = 0;end

%load data
if exist(fullfile(dataPath,'dataVals.mat'),'file')
    load(fullfile(dataPath,'dataVals.mat'),'dataVals')
    bdataVals = 1;
else
    bdataVals = 0;
end


%% define trials to analyze based on conditions
trials2analyze = [];
for c = 1:length(conds2analyze)
    condname = conds2analyze{c};
    trials2analyze = [trials2analyze expt.inds.conds.(condname)];
end
trials2analyze = sort(trials2analyze);


% extract formants at middle 50% of vowel
ntrials = length(trials2analyze);
F1s = zeros(1,ntrials);
F2s = zeros(1,ntrials);
framedur = 1 / data(1).params.sr*data(1).params.frameLen; % get frame duration
offset = [floor(0.05 / framedur) floor(0.01 / framedur)]; % account for hold time in ost tracking
if bTest;figure;end
for itrial = trials2analyze
    if isfield(data, 'ost_calc') && ~isempty(data(itrial).ost_calc)
        ost = data(itrial).ost_calc; %user-configured values
    else
        ost = data(itrial).ost_stat; %values from initial settings
    end
    if bdataVals
        F1s(itrial) = median(midnperc(dataVals(itrial).f1,50), 'omitnan');
        F2s(itrial) = median(midnperc(dataVals(itrial).f2,50), 'omitnan');
    elseif any(any(ost==ostInds,2)) 
        vowelFrames = find(any(ost == ostInds,2)|any(ost == ostInds+1,2)); % get indices to vowel
        vowelFrames = vowelFrames(1)-offset(1):vowelFrames(end)-offset(2); %account for offset in ost tracking
        vowelFmts = data(itrial).fmts(vowelFrames,:);
        F1s(itrial) = median(midnperc(vowelFmts(:,1),50), 'omitnan');
        F2s(itrial) = median(midnperc(vowelFmts(:,2),50), 'omitnan');
    else
        F1s(itrial) = NaN;
        F2s(itrial) = NaN;
    end
    if bTest
        plot(data(itrial).fmts)
        vline(vowelFrames(1),'k');
        vline(vowelFrames(end),'k');
        pause
    end
end

% get per-vowel means
for v = 1:length(expt.vowels)
    vow = expt.vowels{v};
    F1dist = [];
    F2dist = [];
    if isfield(expt,'bExcl')
        vowInds = intersect(expt.inds.vowels.(vow),find(~expt.bExcl));
        vowInds = intersect(vowInds, trials2analyze);
    else
        vowInds = expt.inds.vowels.(vow);
        vowInds = intersect(vowInds, trials2analyze);
    end
    if bRmOutliers
        tempDat1 = F1s(vowInds);
        tempDat2 = F2s(vowInds);
        tempDat1(isoutlier(tempDat1,'grubbs')) = NaN;
        tempDat2(isoutlier(tempDat2,'grubbs')) = NaN;
        F1s(vowInds) = tempDat1;
        F2s(vowInds) = tempDat2;
    end
    % compute distance of each token to median values of each vowel's distribution
    F1dist = F1s(vowInds) -  median(F1s(vowInds), 'omitnan'); 
    F2dist = F2s(vowInds) -  median(F2s(vowInds), 'omitnan');
    % find the index of the token that is closest to the median values
    [~,minLoc] =  min(sqrt(F1dist.^2 + F2dist.^2));
    TargetIx.(vow) = vowInds(minLoc);
    % save the f1/f2 values for that token
    TargetIx.fmts.(vow) = [F1s(vowInds(minLoc)) F2s(vowInds(minLoc))];
    % get median f1/f2 values for each vowel category
    fmtMedians.(vow) = [median(F1s(vowInds), 'omitnan') median(F2s(vowInds), 'omitnan')];
    % get mean f1/f2 values for each vowel category
    fmtMeans.(vow) = [mean(F1s(vowInds), 'omitnan') mean(F2s(vowInds), 'omitnan')];
    % get standard deviation 
    fmtStds.(vow) = [std(F1s(vowInds), 'omitnan') std(F2s(vowInds), 'omitnan')];
end
