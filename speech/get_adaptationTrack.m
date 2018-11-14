function [avg,baseavg,normavg] = get_adaptationTrack(dataPath,avgtype,avgval,binsize,toTrack)
%GET_ADAPTATIONTRACK  Adaptation for a single subject across an experiment.
%   Detailed explanation goes here

if nargin < 2 || isempty(avgtype), avgtype = 'mid'; end
if nargin < 3 || isempty(avgval), avgval = 50; end
if nargin < 4 || isempty(binsize), binsize = 10; end
if nargin < 5 || isempty(toTrack), toTrack = {'f1' 'f2'}; end

% get experiment info
load(fullfile(dataPath,'expt.mat'),'expt');
if isfield(expt,'nBaseline')
    nBaseline = exptInfo.nBaseline;
else
    warning('Setting number of baseline trials to default (80).')
    nBaseline = 80;
end

% get data
load(fullfile(dataPath,'dataVals.mat'))
ntrials = length(dataVals);
fs = get_fs_from_taxis(dataVals(1).ftrack_taxis);

% define averaging function (which timepoints/percent, etc.)
switch avgtype
    case 'mid'
        avgfn = @(fmttrack) midnperc(fmttrack,avgval);
    case 'first'
        avgfn = @(fmttrack) fmttrack(1:min(ceil(avgval/fs),length(fmttrack)));
    case 'next'
        avgfn = @(fmttrack) fmttrack(min(ceil(avgval/fs)+1,length(fmttrack)):min(2*ceil(avgval/fs),length(fmttrack)));
    case 'then'
        avgfn = @(fmttrack) fmttrack(min(2*ceil(avgval/fs)+1,length(fmttrack)):min(3*ceil(avgval/fs),length(fmttrack)));
end

for i=1:length(toTrack)
    % calculate the average over each of the trials
    avg.allTrials.(toTrack{i}) = zeros(1,ntrials);
    for itrial = 1:ntrials
        avg.allTrials.(toTrack{i})(itrial) = nanmean(avgfn(dataVals(itrial).(toTrack{i})));
    end
    % calculate baseline & normalized average
    baseavg.allTrials.(toTrack{i}) = nanmean(avg.allTrials.(toTrack{i})(1:nBaseline));
    normavg.allTrials.(toTrack{i}) = avg.allTrials.(toTrack{i}) - baseavg.allTrials.(toTrack{i});
    
    % calculate bins
    if binsize ~= 1
        nbins = floor(ntrials/binsize);
        avg.bins.(toTrack{i}) = zeros(1,nbins);
        for ibin=1:nbins
            avg.bins.(toTrack{i})(ibin) = nanmean(avg.allTrials.(toTrack{i})(binsize*(ibin-1)+1:binsize*ibin));
        end
        % calculate baseline % normalized average
        baseavg.bins.(toTrack{i}) = nanmean(avg.bins.(toTrack{i})(1:floor(nBaseline/binsize)));
        normavg.bins.(toTrack{i}) = avg.bins.(toTrack{i}) - baseavg.bins.(toTrack{i});
    end
end