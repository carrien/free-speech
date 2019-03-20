function trialList = check_nevents(dataPath,trialdir,nEvents)

% checks to make sure that number of events exists for each trial in 
% experiment
% nEvents is a [list]

trialList = []

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end
if nargin < 3 || isempty(nEvents), nEvents = [0 1 4]; end

load(fullfile(dataPath,'expt.mat'));
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
sortedTrials = get_sortedTrials(trialPath);

% extract tracks from each trial
for i = 1:length(sortedTrials)
    trialnum = sortedTrials(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename));
    
    
    % skip bad trials
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params) && ~trialparams.event_params.is_good_trial
        sprintf('bad trial: %d', trialnum)
    else
        if exist('trialparams','var') ...
                && isfield(trialparams,'event_params') ...
                && ~isempty(trialparams.event_params) 
            user_event_times = sort(trialparams.event_params.user_event_times);
        else
            user_event_times = [];
        end
        
        n_events = length(user_event_times);
    end
    if ~exist('n_events','var')
        sprintf('warning: no events found for trial %d',trialnum)
    else
        if ~ismember(n_events,nEvents)
            sprintf('%d events found in trial %d (expected %d or fewer)',n_events,trialnum,max(nEvents));
            trialList = [trialList trialnum];
        end
    end
        % find first syllable vowel onset
        % changed onset_time to onset_time1
    
end
