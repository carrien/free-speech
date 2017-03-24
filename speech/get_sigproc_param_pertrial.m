function [paramvals] = get_sigproc_param_pertrial(dataPath,param,trialdir)
%GET_SIGPROC_PARAM_PERTRIAL  Extracts values of a given parameter for all trials in an experiment.

if isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(trialdir), trialdir = 'trials'; end

trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
W = what(trialPath);
matFiles = [W.mat];

% Strip off '.mat' and sort
filenums = zeros(1,length(matFiles));
for i = 1:length(matFiles)
    [~, name] = fileparts(matFiles{i});
    filenums(i) = str2double(name);
end
sortedfiles = sort(filenums);

for i = 1:length(sortedfiles)
    trialnum = sortedfiles(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename));
    paramvals(i) = trialparams.sigproc_params.(param);
end