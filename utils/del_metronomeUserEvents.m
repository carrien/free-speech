function [] = del_metronomeUserEvents(dataPath, trials, nEvents)
% OVERALL DESCRIPTION: Preserves some user events and deletes the others.
% The default is to delete every event except the (chronologically) first
% one in every trial.
%
% Users may specify (1) how many events to save and (2) which trials
% undergo user event deletion. Within each trial, events are saved in
% chronological order.
%
%
% GENERAL METHOD:
% Takes in trial files, identifies which user events should be saved by
% name and time, stores these events in an array, and then feeds that array
% back into the trial information in
% trialparams.event_params.user_event_times and
% trialparams.event_params.userevent_names. All other events are overridden
% and thus deleted.
%
%
% INPUT VARIABLES:
% dataPath: location of the folder with experiment's data. Typically looks
% like nesstlab > experiments > [experimentName] > acousticdata >
% [participantID] ( > [experimentalPhase]).
%
% trials: Which trials' user events will be sorted and deleted. May be a
% double (e.g., 4) or a vector with doubles (e.g., [1:4], [1,3])
% If users specify a trial that does not exist, then they will recieve a warning.
% del_metronomeUserEvents(): alters all trials in the folder
% del_metronomeUserEvents([], 1): alters trial 1
% del_metronomeUserEvents([], [1,3]): alters trails 1 and 3 but not trial 2
% del_metronomeUserEvents([], [3:5]): alters trials 3-5
%
% nEvents: number of events to be saved. The default is to save 1
% event. All saved events are the chronologically first ones.
% del_metronomeUserEvents([], [], 1): saves the first events
% del_metronomeUserEvents([], [], 4): saves the first four events
% del_metronomeUserEvents([], [], 0): all events are deleted
% 
%
% LIMITATIONS:
% All saved events occur from the chronologically first event onwards.
% There is currently no way to, for example, save the last event and delete the
% others.
% 
% Similarly, all events are saved consecutively. There is no way to save
% the first and third events without also saving the second one.
%
% Saved events retain their names. If there was a cell array of event
% names like {'uev3', 'uev3', 'uev1'} in chronological order, the default
% output would be {'uev3'}. The user would have to rename the event to 'uev1'
% manually.
%
%
% Initiated SRB 2025-11-06

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trials), trials = []; end
if nargin < 3 || isempty(nEvents), nEvents = 1; end

%%
% load in expt and data
load(fullfile(dataPath, 'expt.mat')); 
if isempty(trials)
    trials = 1:expt.ntrials; 
end
trialOutFolder = 'trials_signalOut'; 

%%
% delete user events
for t = trials
    trialFileName = [num2str(t) '.mat']; 
    try
        load(fullfile(dataPath, trialOutFolder, trialFileName)); 
    catch
        warning('No signalOut audioGUI file found for trial %d', t); 
        continue; 
    end
    if trialparams.event_params.is_good_trial
        % sort ticks and create arrays into which ticks will be saved
        nTicks = length(trialparams.event_params.user_event_times); 
        [~, indexTimes] = sort(trialparams.event_params.user_event_times);
        sortTimes = [];
        sortNames = {};
        % determine if there are enough ticks to be deleted
        if nTicks < nEvents
            warning('The number of saved events is greater than the existing number in the file. Skipping trial %d.', t); 
            continue; 
        end
        % delete ticks
        for m = 1:nTicks
            if(indexTimes(m) <= nEvents)
                sortTimes(indexTimes(m)) = trialparams.event_params.user_event_times(m);            
                sortNames(indexTimes(m)) = trialparams.event_params.user_event_names(m);

            end
        end
        trialparams.event_params.user_event_times = sortTimes;
        trialparams.event_params.user_event_names = sortNames;
        save(fullfile(dataPath, trialOutFolder, trialFileName), 'sigmat', 'trialparams');
    else
        warning('Trial %d marked as bad trial. Skipping', t); 
    end
    
end

end