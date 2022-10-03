function [] = add_breathyVoiceEvent(dataPath, afterEvent, beforeEvent, breathyEventName, trials, buffer, bSaveCheck)
% Function to add an event "breathyStart" to an existing trial variable. Made for timeWrap but can be general
% 
% 1. Looks for event with the name in arg afterEvent. 
% 2. Looks for event with the name in arg beforeEvent. 
% 3. Splits the difference
% 
% Event goes at the end of the structure, so beware if you are running any scripts that assume temporal order to match event
% order. 
% 
% Input arguments: 
% 1. dataPath: the directory that has the data/expt, and trials folder. Defaults to working dir
% 2. afterEvent: the event you want to put the breathy event after. Usually something like cBurst. Defaults to empty, which
% searches for the FIRST event that has the word "burst" in (not case sensitive, so it'll find both cburst and cBurst)
% 3. beforeEvent: the event you want to put the breathy event before. Usually something like v2Start. Defaults to empty,
% which then just refers to the afterEvent
% --- NB: If neither events are specified/found, it'll just go into the middle of the trial
% 4. breathyEventName: what you want to call your breathy event. Defaults to breathyStart
% 5. trials: which trials you want to do it on. Defaults to all. 
% 6. buffer: signalIn or signalOut. Defaults to signalIn. 
% 7. bSaveCheck: if you want to be asked if you want to save over every time. Defaults to 0 (no), because this is a script to
% add something to a pre-existing file. 
% 
% 
% Initiated RK 2021-09-13
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2, afterEvent = []; end
if nargin < 3, beforeEvent = []; end
if nargin < 4 || isempty(breathyEventName), breathyEventName = 'breathyStart'; end
if nargin < 6 || isempty(buffer), buffer = 'signalIn'; end
if nargin < 7 || isempty(bSaveCheck), bSaveCheck = 0; end

%% Load in data
fprintf('Loading trial data... ');
load(fullfile(dataPath,'data.mat'), 'data')
load(fullfile(dataPath,'expt.mat'), 'expt')
fprintf('Done\n');

params = expt.audapterParams;

% Get the word
stimWord = expt.listWords{1}; % works for timeAdapt and timeAdapt variants


% get number of trials
ntrials = expt.ntrials;
if nargin < 5 || isempty(trials), trials = 1:ntrials; end

% Get sampling rates, etc. 
fs = expt.audapterParams.sr;
frameLength = expt.audapterParams.frameLen; 
ostFactor = fs/frameLength; 

%% Change working to person-specific if available
% So that the buffer parameters are set to the actual person's 

if isfield(expt, 'trackingFileLoc')
    trackingFileLoc = expt.trackingFileLoc; 
else
    trackingFileLoc = 'free-speech'; 
end

if isfield(expt, 'trackingFileName')
    trackingFileName = expt.trackingFileName; 
else
    trackingFileName = 'measureFormants'; 
end

% special rules for experiment using multiple OST files. They should be
% using the `trials` input argument to specify trials from one OST at a
% time. See gen_ostUserEvents_multiOst.m for example wrapper function.
if iscell(expt.trackingFileName)
    expt.trackingFileName = expt.listWords{trials(1)};
end


%% Create user events for input signal

switch buffer
    case 'signalIn'
        trialfolder = 'trials'; 
    case 'signalOut'
        trialfolder = 'trials_signalOut'; 
end 
if ~exist(fullfile(dataPath,trialfolder), 'dir') % 
    mkdir(fullfile(dataPath,trialfolder))
end

fprintf('Generating and saving events... \n')
for i = 1:length(trials)
    itrial = trials(i); 
    if ~mod(itrial, 25)
        fprintf('%d\n', itrial)
    else
        fprintf('%d ', itrial)
    end
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial));
    
    % Initiate empty so you can use emptiness as a check
    afterix = []; 
    beforeix = [];     
     
    % Load in trial file if it exists
    if isfile(savefile)
        load(savefile);
        % Catches for if all you have is that the trial doesn't have good audio 
        try
            sigproc_params = trialparams.sigproc_params;
        catch
            sigproc_params = get_sigproc_defaults;
        end
        if ~exist('sigmat', 'var'), sigmat = []; end 
        
        try
            plot_params = trialparams.plot_params; 
        catch 
            plot_params = get_plot_defaults;
        end
        
        try
            event_params = trialparams.event_params;
        catch 
            event_params = get_event_defaults;
        end
        
        % Check if you already have events, add breathyStart to the end
        if isfield(event_params, 'user_event_names') && ~isempty(event_params.user_event_names)
            if ismember(breathyEventName, event_params.user_event_names)
                warning(fprintf('There is already an event called %s in trial %d. Skipping this trial.', breathyEventName, itrial)); 
                break; 
            else
                % Add the event at the end
                breathyIx = length(event_params.user_event_names) + 1;               
            end
        else
            breathyIx = 1;             
        end
        
    % If there is no trial file yet, make barebones structure
    else
        sigproc_params = get_sigproc_defaults;
        plot_params = get_plot_defaults;
        sigmat = [];
        trialparams = struct(); 
        event_params = get_event_defaults;
        breathyIx = 1; 
    end
    event_params.user_event_names{breathyIx} = breathyEventName; 
    
    % Look for the 'after' and 'before' events to grab their times
    if ~isempty(afterEvent)
        afterix = find(strcmp(event_params.user_event_names, afterEvent)); 
    else
        % If you didn't specify, find the first event that contains "burst"
        afterix = find(contains(event_params.user_event_names, 'burst', 'ignoreCase', 1), 1, 'first'); 
    end

    if ~isempty(beforeEvent)
        beforeix = find(strcmp(event_params.user_event_names, beforeEvent)); 
    else
        % If you didn't specify, then it'll just be empty (this is because there's no reliable prediction of what the event
        % will be called, and the burst event could potentially be the last event in the segmentation)
        beforeix = []; 
    end

    % Check if you've found the events
    trialDur = length(data(itrial).signalIn) / fs; 
    if isempty(afterix) && isempty(beforeix)
        % If you didn't find any events, just put it at the midpoint of the trial
        breathyTime = trialDur/2; 
    elseif isempty(afterix) && ~isempty(beforeix)
        % If you only found before time, you'll put it 50 ms before that
        breathyTime = event_params.user_event_times(beforeix) - 0.05; 
    elseif isempty(beforeix) && ~isempty(afterix)
        % If you only found after time, you'll put it 50 ms after that
        breathyTime = event_params.user_event_times(afterix) + 0.05;
    elseif ~isempty(afterix) && ~isempty(beforeix)
        % If you found both, then you'll put it in the middle of the two 
        breathyTime = (event_params.user_event_times(afterix) + event_params.user_event_times(beforeix))/2; 
    end
    
    % Just in case you had some weirdo tracking
    if breathyTime < 0
        breathyTime = 0.01; 
    elseif breathyTime > trialDur
        breathyTime = trialDur - 0.01; 
    end
    
    event_params.user_event_times(breathyIx) = breathyTime;  
    trialparams.sigproc_params = sigproc_params; 
    trialparams.plot_params = plot_params; 
    trialparams.event_params = event_params; 
    
    % Save structures into the trial file (both in and out) 
    if bSaveCheck, bSave = savecheck(savefile); else, bSave = 1; end
    
    if bSave, save(savefile,'sigmat','trialparams'); end
    % Put the output times, etc. into the event_params field for output saving 

    
end
fprintf('Done\n')
end %EOF