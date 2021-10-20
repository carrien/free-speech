function [] = check_trialDurations(dataPath,bPlot)
%CHECK_TRIALDURATIONS Function for visualizing the length of signalIn over
%the course of an experiment.
%   CHECK_TRIALDURATIONS(DATAPATH,BPLOT)
%       This function plots the signalIn durations over the course of an
%       experiment run given the DATAPATH containing it's data.mat file
%
%   ARGUMENTS
%       DATAPATH - Path to data.mat to load signalIn fields from.
%       BPLOT - whether or not a visualization of the trial durations
%       should be shown. 
%
%   OUTPUT
%       A figure is created with the signalIn data, a moving average of
%       durations, and lines indicating the mean and 2 standard deviations 
%       from mean. Also information about the number of trials above/below 
%       the 2std marks are sent to the console for viewing. A high std is a
%       good indication that something is changing your trial lengths more
%       generally, and the long/short trials are useful for finding individual
%       instances of anomalous trial lengths. 
%

%% Default Arguments
if nargin < 1 || isempty(dataPath), dataPath = cd; end %Default data path is MATLAB working directory.
if nargin < 2 || isempty(bPlot), bPlot = 1; end

%% Load data and expt
fprintf('Loading Data...\n');
load(fullfile(dataPath,'data.mat'),'data');
fprintf('Loading Expt...\n');
load(fullfile(dataPath,'expt.mat'),'expt');

%% Determine signalIn durations

trialLength = zeros(1,expt.ntrials);

%TODO: vectorize this?
for trialNum = 1:expt.ntrials
    trialLength(trialNum) = length(data(trialNum).signalIn)/data(trialNum).params.sr;
end

meanDur = mean(trialLength);
stdDur = std(trialLength);

upperThreshold = meanDur + 2*(stdDur);
lowerThreshold = meanDur - 2*(stdDur);
longTrials = find(trialLength > upperThreshold);
shortTrials = find(trialLength < lowerThreshold);

fprintf('Throughout this experiment there were: \n %s long trials (2 std above mean) \n and %s short trials (2 below mean).\n\n', num2str(length(longTrials)), num2str(length(shortTrials)));
fprintf('The mean signalIn duration is %s seconds \n and the standard deviation is %s seconds \n\n', num2str(meanDur), num2str(stdDur));

if stdDur > .1 %standard deviation greater than 100 ms
    warning('The standard deviation of this data is very high (greater than 100 ms), its possible something is causing your trials grow in length');
end

fprintf('These trials were: \n Long trials: %s \n Short trials: %s \n', num2str(longTrials), num2str(shortTrials)); 


if bPlot
    
    figure();
    hold on
    title(sprintf('SignalIn Duration per Trial for %s %s', expt.name, expt.snum))
    plot(1:expt.ntrials,trialLength)
    xlim([1 expt.ntrials])
    xlabel('Trial Number')
    ylabel('Duration of SignalIn (Seconds)')
    window = 5; %5 Trials in moving mean window.
    movAvg = movmean(trialLength,window);
    plot(1:expt.ntrials,movAvg,'k-','LineWidth',2)
    yline(meanDur,'-','mean duration');
    yline(upperThreshold,'r--','+2std')
    yline(lowerThreshold,'r--','-2std')
    legend('Trial Lengths','5-Trial Moving Average','Location','northwest')
    
end

end