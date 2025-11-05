function [] = del_metronomeUserEvents(dataPath, trials, nEvents)
% OVERALL DESCRIPTION:
% Takes in trial files from trials_signalOut, identifies the user event
% that is chronologically first, and adds those saved events back into
% trialparams.event_params.user_event_times and
% trialparams.event_params.user_event_names. This effectively deletes all
% other events.
% 
% Users may specify how many events they wish to save. Events are
% saved in chronological order.
%
%
% INPUT VARIABLES:
% dataPath is the path to the data. This will typically look like
% nesstlab > experiments > [experimentName] > [participantID] >
% [experimentalPhase].
%
% trials represents which trials' user events will be sorted and deleted.
% Users may specify one trial or multiple. If users specify a trial that
% does not exist, then they will recieve a warning.
% del_metronomeUserEvents(): alters all trials in the folder
% del_metronomeUserEvents([], 1): alters trial 1
% del_metronomeUserEvents([], [3:5]): alters trials 3-5
%
% nEvents is the number of events to be saved. The default is to save 1
% event. All saved events are the chronologically earliest.
% del_metronomeUserEvents([], [], 1): saves the first events
% del_metronomeUserEvents([], [], 4): saves the first four events
% del_metronomeUserEvents([], [], 0): all events are deleted
% 
%
% LIMITATIONS:
% All saved events occur from the chronologically first event onwards.
% There is currently no way to, say, save the last event and delete the
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
% Initiated SRB 2025-11-04

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