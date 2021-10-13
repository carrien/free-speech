function [] = check_trialDurations(dataPath,bPlot)
%CHECK_TRIALDURATIONS:
%   CHECK_TRIALDURATIONS(DATAPATH)
%
%   ARGUMENTS
%       DATAPATH
%
%   OUTPUT
%

%% Default Arguments
if nargin < 1 || isempty(dataPath), dataPath = cd; end %Default data path is MATLAB working directory.
if nargin < 2 || isempty(bPlot), bPlot = 0; end

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

if bPlot
    
    figure();
    hold on
    plot(1:expt.ntrials,trialLength)
    xlabel('Trial Number')
    ylabel('Duration of SignalIn (Seconds)')
    window = 10; %5 Trials in moving mean window.
    movAvg = movmean(trialLength,window);
    plot(1:expt.ntrials,movAvg,'k-','LineWidth',2)
    yline(expt.timing.stimdur,'-','expt.timing.stimdur');
    yline(upperThreshold,'r--','+10%')
    yline(lowerThreshold,'r--','-10%')
    legend('Trial Lengths','5-Trial Moving Average','Location','northwest')
    
end

end