function [ ] = plot_sigprocParams_byCond(dataPath,grouping,trialdir)
%GET_SIGPROCPARAMS_PERTRIAL  Get params across multiple experiment trials.
%   PARAMS = GET_SIGPROCPARAMS_PERTRIAL(DATAPATH,GROUPING,COND) loads files
%   from DATAPATH/TRIALDIR/ and returns the parameters used by wave_viewer
%   in a struct array PARAMS. GROUPING and COND are optional variables that
%   specify a subset of trials, e.g. GROUPING = 'word' and COND = 'add'
%   would only return trials in which the word was "add".
%
%CN 2019

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(grouping), grouping = 'words'; end
if nargin < 3 || isempty(trialdir), trialdir = 'trials'; end

load(fullfile(dataPath,'expt.mat'),'expt');
groups = fieldnames(expt.inds.(grouping));
ngroups = length(groups);

nLPCs = get_sigproc_param_pertrial(dataPath,'nlpc',trialdir);
preemphs = get_sigproc_param_pertrial(dataPath,'preemph',trialdir);

figure;
for g = 1:ngroups
    group = groups{g};
    inds = expt.inds.(grouping).(group);

    subplot(2,ngroups,g)
    plot(nLPCs(inds));
    title(sprintf('nLPCs: %s',group))

    subplot(2,ngroups,g+ngroups)
    plot(preemphs(inds));
    title(sprintf('preemphs: %s',group))
end

figure;
for g = 1:ngroups
    group = groups{g};
    inds = expt.inds.(grouping).(group);

    subplot(2,ngroups,g)
    histogram(nLPCs(inds));
    title(sprintf('nLPCs: %s',group))

    subplot(2,ngroups,g+ngroups)
    histogram(preemphs(inds));
    title(sprintf('preemphs: %s',group))
end
