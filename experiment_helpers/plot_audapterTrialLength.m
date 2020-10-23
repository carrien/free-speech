function [] = plot_audapterTrialLength(dataPath)

if nargin < 1, dataPath = pwd; end

fprintf('Loading data...')
load(fullfile(dataPath,'data.mat'))
load(fullfile(dataPath,'expt.mat'))
fprintf('Done\n')

if isfield(expt.audapterParams,'sr')
    sr = expt.audapterParams.sr; 
elseif isfield(data(1).params,'sRate')
    sr = data(1).params.sRate;     
else
    sr = 16000; 
end

trialVector = 1:length(data); 
trialDur = zeros(1,length(data)); 

for a = 1:length(data)
    trialDur(a) = length(data(a).signalIn) / sr; 
end

figure
scatter(trialVector,trialDur)

if isfield(expt,'crashTrials') && ~isempty(expt.crashTrials)
    hold on
    scatter(trialVector(expt.crashTrials), trialDur(expt.crashTrials),'r') 
end

hold on
plot(trialVector, trialDur)

title(['Duration of trials for Audapter experiment ' expt.name ' ' expt.snum]) 
xlabel('Trial number')
ylabel('Duration (s)') 



end