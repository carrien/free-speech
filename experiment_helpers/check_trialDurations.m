function [] = check_trialDurations(dataPath,bPlot)
%CHECK_TRIALDURATIONS Function for visualizing the length of signalIn over
%the course of an experiment.
%   CHECK_TRIALDURATIONS(DATAPATH)
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
%       durations, and lines indicating expt.timing.stimdur, 10 percent
%       above that, and 10 percent below it. Also information about the
%       number of trials above/below the 10 percent lines is sent to the
%       console for viewing. 
%

%% Default Arguments
if nargin < 1 || isempty(dataPath), dataPath = cd; end %Default data path is MATLAB working directory.
if nargin < 2 || isempty(bPlot), bPlot = 1; end

%% Load data and expt
fprintf('Loading Data...\n');
load(fullfile(dataPath,'data.mat'),'data');
fprintf('Loading Expt...\n');
load(fullfile(dataPath,'expt.mat'),'expt');

%% Determine average trial duration

recordLength = expt.timing.stimdur; %+ expt.timing.interstimdur + expt.timing.interstimjitter;
thresholdPercentage = .10;
threshold = recordLength * thresholdPercentage;
upperThreshold = recordLength + threshold;
lowerThreshold = recordLength - threshold;

trialLength = zeros(1,expt.ntrials);
longTrials = [];
shortTrials = [];

for trialNum = 1:expt.ntrials
    trialLength(trialNum) = length(data(trialNum).signalIn)/data(trialNum).params.sr;
    if trialLength(trialNum) > upperThreshold
        longTrials = [longTrials trialNum];
    elseif trialLength(trialNum) < lowerThreshold
        shortTrials = [shortTrials trialNum];
    end
end

warning('Throughout this experiment, there were %s long trials (>10 percent above expt.timing.stimdur) and %s short trials (<10 above expt.timing.stimdur).\n\n', num2str(length(longTrials)), num2str(length(shortTrials)))

warning('These trials were: \n Long trials: %s \n Short trials: %s', num2str(longTrials), num2str(shortTrials)) 


if bPlot
    
    figure();
    hold on
    plot(1:expt.ntrials,trialLength)
    xlabel('Trial Number')
    ylabel('Duration of SignalIn (Seconds)')
    window = 5; %5 Trials in moving mean window.
    movAvg = movmean(trialLength,window);
    plot(1:expt.ntrials,movAvg,'k-','LineWidth',2)
    yline(expt.timing.stimdur,'-','expt.timing.stimdur');
    yline(upperThreshold,'r--','+10%')
    yline(lowerThreshold,'r--','-10%')
    legend('Trial Lengths','5-Trial Moving Average','Location','northwest')
    
end

end