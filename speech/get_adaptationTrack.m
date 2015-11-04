function [avg,baseavg,normavg] = get_adaptationTrack(exptName,snum,subdirname,avgtype,avgval,binsize,toTrack)
%GET_ADAPTATIONTRACK  Adaptation for a single subject across an experiment.
%   Detailed explanation goes here

if nargin < 3, subdirname = []; end
if nargin < 4 || isempty(avgtype), avgtype = 'mid'; end
if nargin < 5 || isempty(avgval), avgval = 50; end
if nargin < 6 || isempty(binsize), binsize = 10; end
if nargin < 7 || isempty(toTrack), toTrack = {'f1' 'f2'}; end

% get experiment info
exptInfo = get_exptInfo(exptName);
if isfield(exptInfo,'nbasetrials')
    nbasetrials = exptInfo.nbasetrials;
else
    warning('Setting number of baseline trials to default (80).') %#ok<WNTAG>
    nbasetrials = 80;
end

% get data
dataPath = getAcoustSubjPath(exptName,snum,subdirname);
load(fullfile(dataPath,'dataVals.mat'))
ntrials = length(dataVals);
fs = diff(dataVals(1).ftrack_taxis); fs = fs(1);

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
    % calculate the average over each of the 800 trials
    avg.allTrials.(toTrack{i}) = zeros(1,ntrials);
    for nt=1:ntrials
        avg.allTrials.(toTrack{i})(nt) = nanmean(avgfn(dataVals(nt).(toTrack{i})));
    end
    % calculate baseline & normalized average
    baseavg.allTrials.(toTrack{i}) = nanmean(avg.allTrials.(toTrack{i})(1:nbasetrials));
    normavg.allTrials.(toTrack{i}) = avg.allTrials.(toTrack{i}) - baseavg.allTrials.(toTrack{i});
    
    % calculate bins
    if binsize ~= 1
        nbins = floor(ntrials/binsize);
        avg.bins.(toTrack{i}) = zeros(1,nbins);
        for nb=1:nbins
            avg.bins.(toTrack{i})(nb) = nanmean(avg.allTrials.(toTrack{i})(binsize*(nb-1)+1:binsize*nb));
        end
        % calculate baseline % normalized average
        baseavg.bins.(toTrack{i}) = nanmean(avg.bins.(toTrack{i})(1:floor(nbasetrials/binsize)));
        normavg.bins.(toTrack{i}) = avg.bins.(toTrack{i}) - baseavg.bins.(toTrack{i});
    end
end