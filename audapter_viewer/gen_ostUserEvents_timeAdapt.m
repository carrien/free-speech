function [varargout] = gen_ostUserEvents_timeAdapt(dataPath,events,trials,bOutput,bSaveCheck,bBuffersOut,bRefreshOst)
% DATA = gen_ostUserEvents_timeAdapt
% Generates user events for a set of trials (one condition) based on OST changes. 
% 
% Renames the user events with descriptive names
%
% Also generates a wave_viewer_params file that has the Hz value set to 0, 10,000 so that the sibilant noise is visible 
% 
%Inputs:
%   - dataPath: path where data.mat and expt.mat for the main trials are. Leave empty to use current directory
%   - events: which events or OST statuses you want to generate a UEV for. Can give in numbers 
%   - trials: the trials you want to generate events for
%   - bOutput: if you also want to do this for signalOut
%   - bSaveCheck: if you want to be asked for every trial if you want to overwrite, if this trial file already exists. Defaults to 1
%   - bBuffersOut: if you want the function to spit out the buffers used for making event times. Buffers are
%   the parameter in the OST that tells Audapter how long a condition needs to be satisifed before the next
%   OST event can be reached. 
%   - bRefreshOst: if you want to force refresh to master the OST file after. Defaults to 0 to prevent
%   infinite parameter readjustment in experiments. 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(events), events = []; end
if nargin < 4 || isempty(bOutput), bOutput = 0; end
if nargin < 5 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 6 || isempty(bBuffersOut), bBuffersOut = 0; end
if nargin < 7 || isempty(bRefreshOst), bRefreshOst = 0; end


%% Load in data
fprintf('Loading trial data... ');
load(fullfile(dataPath,'data.mat'), 'data')
load(fullfile(dataPath,'expt.mat'), 'expt')
fprintf('Done\n');

params = expt.audapterParams;

% Get the prefix of the ost file (often the stimulus word itself)
switch expt.name
    case 'dipSwitch'
        stimWord = expt.words{expt.round};
    case 'simonMultisyllable'
        stimWord = 'pedXXX';
    case 'simonMultisyllable_v2'
        stimWord = 'sevXXX';
    case 'taimComp'
        
    otherwise
        stimWord = expt.listWords{1}; % works for timeAdapt and timeAdapt variants
end

% get number of trials
ntrials = expt.ntrials;
if nargin < 3 || isempty(trials), trials = 1:ntrials; end

% Get sampling rates, etc. 
fs = expt.audapterParams.sr;
frameLength = expt.audapterParams.frameLen; 
ostFactor = fs/frameLength; 

%% Change working to person-specific if available
% So that the buffer parameters are set to the actual person's 
% special rules for experiment using multiple OST files. They should be
% using the `trials` input argument to specify trials from one OST at a
% time. See gen_ostUserEvents_multiOst.m for example wrapper function.
if isfield(expt, 'trackingFileName')
    if iscell(expt.trackingFileName)
        expt.trackingFileName = expt.trackingFileName{1}; 
    else
        expt.trackingFileName = expt.trackingFileName;
    end
elseif isfield(expt, 'name') && strcmp(expt.name, 'timeAdapt')
    expt.trackingFileName = expt.listWords{1};
else
    expt.trackingFileName = 'measureFormants';
end

% Reset OST file to how it was when the experiment ran
set_subjOstParams_auto(expt, data);

%% Set up OST recognition 
% Pre-defined available events for stimulus words. Covers "capper" and "a capper" types. 
if isfield(expt, 'trackingFileLoc')
    [ost.eventNames,ost.events] = get_ostEventNamesNumbers(expt.trackingFileLoc,expt.trackingFileName,events,1,1); 
    triggerName = get_ostEventNamesNumbers(expt.trackingFileLoc,expt.trackingFileName,{'trigger'},1,0); 
else
    [ost.eventNames,ost.events] = get_ostEventNamesNumbers([],stimWord,events,1,1); 
    triggerName = get_ostEventNamesNumbers([],stimWord,{'trigger'},1,0); 
end

ost.trigger = triggerName{1}; 

% Deprecated now, work done by calling get_ostEventNamesNumber_timeAdapt
% 
% if strcmp(stimWord,'capper')
%     eventNos = str2double(get_ost(expt.name, stimWord, 'list')); 
%     possibleEvents = {'v1Start' 'cStart' 'cBurst' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
%     eventNames = possibleEvents(end-(length(eventNos) - 1):end); 
%     triggerNo = get_pcf(expt.name,stimWord,'ostStat_initial'); 
%     triggerName = eventNames{triggerNo == eventNos}; 
%     ost.trigger = triggerName;      
% elseif strcmp(stimWord, 'gapper') 
%     eventNos = str2double(get_ost(expt.name, stimWord, 'list'));
%     possibleEvents = {'v1Start' 'cStart' 'cBurst' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
%     eventNames = possibleEvents(end-(length(eventNos) - 1):end); 
%     triggerNo = get_pcf(expt.name,stimWord,'ostStat_initial'); 
%     triggerName = eventNames{triggerNo == eventNos}; 
%     ost.trigger = triggerName;       
% elseif strcmp(stimWord, 'sapper')
%     eventNos = str2double(get_ost(expt.name, stimWord, 'list'));
%     possibleEvents = {'v1Start' 'cStart' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
%     eventNames = possibleEvents(end-(length(eventNos) - 1):end); 
%     triggerNo = get_pcf(expt.name,stimWord,'ostStat_initial'); 
%     triggerName = eventNames{triggerNo == eventNos}; 
%     ost.trigger = triggerName;           
% elseif strcmp(stimWord, 'zapper')
%     eventNos = str2double(get_ost(expt.name, stimWord, 'list'));
%     possibleEvents = {'v1Start' 'cStart' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
%     eventNames = possibleEvents(end-(length(eventNos) - 1):end); 
%     triggerNo = get_pcf(expt.name,stimWord,'ostStat_initial'); 
%     triggerName = eventNames{triggerNo == eventNos}; 
%     ost.trigger = triggerName; 
% else 
%     warning('Using default stimulus word events\n')
%     eventNos = get_ost(expt.name,stimWord,'list'); 
%     eventNames = cell(1,length(eventNos)); 
%     for i = 1:length(eventNos)
%         eventNames{i} = ['ost' num2str(eventNos(i))];
%     end
%     triggerNo = get_pcf(expt.name,stimWord,'ostStat_initial'); 
%     triggerName = eventNames{triggerNo == eventNos}; 
% end
% 
% % Integrate "events" arg 
% if nargin < 2 || isempty(events), events = eventNos; end
% % Check that the specified events actually exist in the list
% if iscell(events) % If you input event names
%     % Check for "trigger" and convert if exists
%     if ismember('trigger',events)
%         events{strcmp('trigger',events)} = triggerName; 
%     end    
%     badEvents = events(~ismember(events,eventNames)); 
%     events = events(ismember(events,eventNames)); 
%     if ~isempty(badEvents)
%         warning('Event(s) %s ignored (does not exist for word)\n', [sprintf('%s, ', badEvents{1:end-1}), badEvents{end}])
%     end
%     ost.events = eventNos(ismember(eventNames,events)); 
%     ost.eventNames = eventNames(ismember(eventNames,events)); % This does the job of sorting 
% else % If you input(ted?) event numbers 
%     badEvents = events(~ismember(events,eventNos)); 
%     events = events(ismember(events,eventNos));
%     if ~isempty(badEvents)
%         badEvents = num2cell(badEvents); 
%         warning('Event(s) %s ignored (does not exist for word)\n', [sprintf('%d, ', badEvents{1:end-1}), num2str(badEvents{end})])
%     end
%     ost.events = eventNos(ismember(eventNos,events));
%     ost.eventNames = eventNames(ismember(eventNos,events)); 
% end
% *** end deprecation

nEvents = length(ost.events); 

% Define working OST file
if isfield(expt,'trackingPath')
    trackingPath = expt.trackingPath; 
elseif isfield(expt,'trackingFileLoc')
    trackingPath = expt.trackingFileLoc; 
else
    trackingPath = get_exptRunpath(expt.name); 
end
if isfield(expt,'trackingFileName')
    trackingName = expt.trackingFileName; 
else
    trackingName = stimWord; 
end
ostFN = fullfile(trackingPath,[trackingName 'Working.ost']);
pcfFN = fullfile(trackingPath,[trackingName 'Working.pcf']);

% If a working copy doesn't exist, make one
if exist(ostFN,'file') ~= 2
    refreshWorkingCopy(trackingPath,trackingName,'ost');
end

% Open file and load file line by line into structure finfo
fid = fopen(ostFN,'r');
tline = fgetl(fid);
itrial = 1;
% clear finfo
ostInfo{itrial} = tline;
while ischar(tline)
    itrial = itrial+1;
    tline = fgetl(fid);
    ostInfo{itrial} = tline;
end
fclose(fid);

% ostStatBegin_line = find(strncmp(finfo, num2str(ostStatBegin), 1)); 
% cellfun(@(x) strncmp(x, num2str(ostStatPrev), 1), finfo, 'UniformOutput', 0);


for a = 1:nEvents
    % Grab lag (the OST has to hit a criteria for a given duration)
    % Get the buffer amount for the ostStatBegin (so hand correction is more intuitive) 
    % TO DO: add switch for if you're using frames (/stretch) or duration, etc. 
    if ost.events(a) - 2 > 9
        nComp = 2; 
    else 
        nComp = 1; 
    end
    prevLineComponents = strsplit(ostInfo{strncmp(ostInfo, num2str(ost.events(a) - 2), nComp)}, ' '); 
    % the two is hard-coded---shouldn't matter as long as we don't have any +1 events
    % The additional lag will be the 4th element
    beginPrevHeur = prevLineComponents{2}; 
    % Unless you're using a stretch/span heuristic in which case it will be the number of frames in the 3rd component / framelen
    if contains(beginPrevHeur,'STRETCH')
        ost.eventLag.(ost.eventNames{a}) = str2double(prevLineComponents{3}) * expt.audapterParams.frameLen / expt.audapterParams.sr; 
    else
        ost.eventLag.(ost.eventNames{a}) = str2double(prevLineComponents{4}); 
    end

end

%% Create user events for input signal

trialfolderin = 'trials';     
if ~exist(fullfile(dataPath,trialfolderin), 'dir') % 
    mkdir(fullfile(dataPath,trialfolderin))
end

fprintf('Generating and saving events... \n')
for i = 1:length(trials)
    itrial = trials(i); 
    % Set up savepaths 
    savefilein = fullfile(dataPath,trialfolderin,sprintf('%d.mat',itrial));
    
    % this should preserve bad trial marking from check_audio
    if isfile(savefilein)
        load(savefilein);
        sigproc_params = trialparams.sigproc_params;
        event_params = trialparams.event_params;
        event_params.user_event_names = {}; 
        event_params.user_event_times = []; 
    else
        sigproc_params = get_sigproc_defaults;
        % Should fix the issue with waverunner axes not matching up 
        if isfield(data(itrial).params, 'sr')
            sigproc_params.fs = data(itrial).params.sr; % This assumes that data row and trial are the same. Is currently true as of 10/4/2021
        end
        plot_params = get_plot_defaults;
        sigmat = [];
        trialparams = struct(); 
        event_params = get_event_defaults;
    end
    
    if contains(dataPath, 'taimComp')
        plot_params.hzbounds4plot = [0 6000]; % for taimComp, this is used to see formants, so zooming in on the formants rather than fricative noise
    else
        plot_params.hzbounds4plot = [0 10000]; % to find s/z noise more easily 
    end
    
%     event_params.is_good_trial = 1; % RPK 3/11 why is this line here?? 

    % Get trial duration for ensuring that uevs don't get placed outside
    trialDur = length(data(itrial).signalIn) / fs; 
    
    
    % Find the indices of the status transitions and translate to times
    if isfield(data,'calcOST') && ~isempty(data(itrial).calcOST)
        ost_stat = data(itrial).calcOST; 
    else
        ost_stat = data(itrial).ost_stat; 
    end
    
    % To get the actual original ones, not recalculated
    exp_ost_stat = data(itrial).ost_stat; 

    a = 1; 
    emptyOst = []; 
    for ievent = 1:nEvents
        ost.indices.(ost.eventNames{ievent}) = find((ost_stat == ost.events(ievent)), 1); 
        ost.exp_indices.(ost.eventNames{ievent}) = find((exp_ost_stat == ost.events(ievent)), 1); 
        
        % Translate recalculated OST event times to times (ost.times) and also experiment-generated
        % (ost.exp_times)
        if ~isempty(ost.indices.(ost.eventNames{ievent}))
            ost.times.(ost.eventNames{ievent}) = ost.indices.(ost.eventNames{ievent})/ostFactor;
            ost.exp_times.(ost.eventNames{ievent}) = ost.exp_indices.(ost.eventNames{ievent})/ostFactor;
            % readjust for buffer
            ost.times.(ost.eventNames{ievent}) = ost.times.(ost.eventNames{ievent}) - ost.eventLag.(ost.eventNames{ievent}); 
            ost.exp_times.(ost.eventNames{ievent}) = ost.exp_times.(ost.eventNames{ievent}) - ost.eventLag.(ost.eventNames{ievent});
        
        % If it's empty and not the first event, set as the previous event + 0.05
        elseif isempty(ost.indices.(ost.eventNames{ievent})) && ievent ~= 1
            ost.times.(ost.eventNames{ievent}) = ost.times.(ost.eventNames{ievent-1}) + 0.05; 
            ost.exp_times.(ost.eventNames{ievent}) = ost.exp_times.(ost.eventNames{ievent-1}) + 0.05; 
            emptyOst(a) = ievent; 
            a = a+1; 
        
        % If it's empty and it IS the first event, set as 0.05 and mark as a bad trial
        elseif isempty(ost.indices.(ost.eventNames{ievent})) && ievent == 1
            ost.times.(ost.eventNames{ievent}) = 0.05; 
            ost.exp_times.(ost.eventNames{ievent}) = 0.05; 
            emptyOst(a) = ievent; 
            a = a+1; 
            event_params.is_good_trial = 0; 
        end
        
        % Translate original (experiment-generated) OST event times
%         if ~isempty(ost.exp_indices.(ost.eventNames{ievent}))
%             ost.exp_times.(ost.eventNames{ievent}) = ost.exp_indices.(ost.eventNames{ievent})/ostFactor;
%             % readjust for buffer
%             ost.exp_times.(ost.eventNames{ievent}) = ost.exp_times.(ost.eventNames{ievent}) - ost.eventLag.(ost.eventNames{ievent});        
%         % If it's empty and not the first event, set as the previous event + 0.01
%         elseif isempty(ost.exp_indices.(ost.eventNames{ievent})) && ievent ~= 1
%             ost.exp_times.(ost.eventNames{ievent}) = ost.exp_times.(ost.eventNames{ievent-1}) + 0.01;         
%         % If it's empty and it IS the first event, set as 0.05 and mark as a bad trial
%         elseif isempty(ost.exp_indices.(ost.eventNames{ievent})) && ievent == 1
%             ost.exp_times.(ost.eventNames{ievent}) = 0.05; 
%         end
        
        % check if event times are outside the duration of the trial. Fix and warn if so. 
        if ost.times.(ost.eventNames{ievent}) < 0 
            ost.times.(ost.eventNames{ievent}) = 0.05; 
            fprintf('Event %s for trial %d was placed before beginning of trial. Moved to t = 0.05.\n',ost.eventNames{ievent},itrial)
        elseif ost.times.(ost.eventNames{ievent}) > trialDur
            ost.times.(ost.eventNames{ievent}) = trialDur - 0.05; 
            fprintf('Event %s for trial %d was placed after end of trial. Moved to 0.05 s before end of trial.\n',ost.eventNames{ievent},itrial); 
        end
            
        % send to event_params
        event_params.user_event_times(ievent) = ost.times.(ost.eventNames{ievent}); 
        event_params.user_event_names{ievent} = ost.eventNames{ievent};       

    end
    
    % send original times to data struct
    data(itrial).origOstTime = ost.exp_times;
    
    trialparams.sigproc_params = sigproc_params; 
    trialparams.plot_params = plot_params; 
    trialparams.event_params = event_params; 
    
    if strcmp(expt.name, 'dipSwitch')
        tThreshExceeded = data(itrial).timing.tThreshExceeded;
        uev2 = trialparams.event_params.user_event_times(2);
        
        % use tThreshExceeded for uev1, unless it's drastically far from uev2
        if tThreshExceeded < uev2 && tThreshExceeded > uev2 - 0.25
            trialparams.event_params.user_event_times(1) = tThreshExceeded;
        end
    end
    
    if ~isempty(emptyOst)
        firstMissingEvent = ost.eventNames{emptyOst(1)}; 
        fprintf('Missing input OST events including and after %s for trial %d\n', firstMissingEvent, itrial)
    end
    
    % Mark trial as bad if the trigger never happened
    if isfield(ost.indices,ost.trigger) && isempty(ost.indices.(ost.trigger))
        trialparams.event_params.is_good_trial = 0;
    end
    
    if trialparams.event_params.is_good_trial == 0 
        warning('Trial %d marked bad: no perturbation triggered.\n', itrial)
    end    
    
    % Save structures into the trial file (both in and out) 
    if bSaveCheck, bSaveIn = savecheck(savefilein); else, bSaveIn = 1; end
    
    if bSaveIn, save(savefilein,'sigmat','trialparams'); end
    % Put the output times, etc. into the event_params field for output saving 

    
end
fprintf('Done\n')



%% Create OST events for output signal (if specified) 
if bOutput

    % Grab OST values from expt file and put them into the working file so you are using the actual same parameters 
    [~,oldParam1,oldParam2] = get_ost(expt.name, stimWord, ost.events(strcmp(ost.trigger, ost.eventNames))); % so you can put them back to how they were
    if isfield(expt,'ostParams') && ~isempty(expt.ostParams)
        ppOstParams = expt.ostParams; 
        set_ost(expt.name, stimWord, ost.events(strcmp(ost.trigger, ost.eventNames)), [], ppOstParams{2}, ppOstParams{3}); 
    else
        refreshWorkingCopy(expt.name, stimWord,'ost')
    end

    Audapter('ost',ostFN,0); 
    Audapter('pcf',pcfFN,0); 

    fprintf('Generating output OSTs... ')
    for o = 1:length(trials)
        otrial = trials(o);     
        sigOut = resample(data(otrial).signalOut, params.downFact, 1);
        sigOutFrame = makecell(sigOut, params.frameLen * params.downFact); %  * params.downFact

        AudapterIO('init', params);
        Audapter('reset'); 

        for m = 1:length(sigOutFrame)
            Audapter('runFrame', sigOutFrame{m})
        end
        outputData(otrial) = AudapterIO('getData');          
    end
    fprintf('Done\n')
    % Put the OST back the way it was
    set_ost(expt.name, stimWord, ost.events(strcmp(ost.trigger, ost.eventNames)), [], oldParam1, oldParam2); 

    trialfolderout = 'trials_signalOut'; 

    if ~exist(fullfile(dataPath,trialfolderout), 'dir') % 
        mkdir(fullfile(dataPath,trialfolderout))
    end
    
    %% saving events
    fprintf('Generating and saving output events... \n')
    for i = 1:length(trials)
        itrial = trials(i); 
        % Set up savepaths 
        savefileout = fullfile(dataPath,trialfolderout,sprintf('%d.mat',itrial));
        savefilein = fullfile(dataPath,'trials',sprintf('%d.mat',itrial)); 

        % Assume that nothing exists. It's fine for now...   
%         sigproc_params = get_sigproc_defaults;
%         plot_params = get_plot_defaults;
        plot_params.hzbounds4plot = [0 10000]; % to find s/z noise more easily 

        % this should preserve bad trial marking from check_audio
        if isfile(savefileout)
            load(savefileout);
            event_params = trialparams.event_params;
            event_params.user_event_names = {}; 
            event_params.user_event_times = []; 
        else
            % Check if trial has been marked as an error in signalIn version 
            if isfile(savefilein)
                load(savefilein);
                is_good_trial_in = trialparams.event_params.is_good_trial; 
            else 
                is_good_trial_in = 1; 
            end
            sigproc_params = get_sigproc_defaults;
            plot_params = get_plot_defaults;
            sigmat = [];
            trialparams = struct(); 
            event_params = get_event_defaults;
            event_params.is_good_trial = is_good_trial_in; 
        end
        
        output_event_params = event_params; 
        sigmat = [];

        % Find the indices of the status transitions and translate to times
        output_ost_stat = outputData(itrial).ost_stat;
        a = 1; 
        emptyOst = []; 
        for ievent = 1:nEvents
            output_ost.indices.(ost.eventNames{ievent}) = find((output_ost_stat == ost.events(ievent)), 1); 

            % Same thing but for the output
            if ~isempty(output_ost.indices.(ost.eventNames{ievent}))
                output_ost.times.(ost.eventNames{ievent}) = output_ost.indices.(ost.eventNames{ievent})/ostFactor;

                % readjust for buffer
                output_ost.times.(ost.eventNames{ievent}) = output_ost.times.(ost.eventNames{ievent}) - ost.eventLag.(ost.eventNames{ievent}); 

            % If it's empty and not the first event, set as the previous event + 0.01
            elseif isempty(output_ost.indices.(ost.eventNames{ievent})) && ievent ~= 1
                output_ost.times.(ost.eventNames{ievent}) = output_ost.times.(ost.eventNames{ievent-1}) + 0.01; 
                output_emptyOst(a) = ievent; 
                a = a+1; 

            % If it's empty and it IS the first event, set as 0.05 and mark as a bad trial
            elseif isempty(output_ost.indices.(ost.eventNames{ievent})) && ievent == 1
                output_ost.times.(ost.eventNames{ievent}) = 0.05; 
                output_emptyOst(a) = ievent;
                a = a+1; 
                output_event_params.is_good_trial = 0; 

            end
            
            % check if event times are outside the duration of the trial. Fix and warn if so. 
            if output_ost.times.(ost.eventNames{ievent}) < 0 
                output_ost.times.(ost.eventNames{ievent}) = 0.05; 
                fprintf('Event %s for trial %d was placed before beginning of trial. Moved to t = 0.05.\n',ost.eventNames{ievent},itrial)
            elseif output_ost.times.(ost.eventNames{ievent}) > trialDur
                output_ost.times.(ost.eventNames{ievent}) = trialDur - 0.05; 
                fprintf('Event %s for trial %d was placed after end of trial. Moved to 0.05 s before end of trial.\n',ost.eventNames{ievent},itrial); 
            end

            % send to output structure
            output_event_params.user_event_times(ievent) = output_ost.times.(ost.eventNames{ievent}); 
            output_event_params.user_event_names{ievent} = ost.eventNames{ievent};         

            % send original times to data struct
            data(itrial).output_origOstTime(ievent) = output_ost.times.(ost.eventNames{ievent}); 

        end

        trialparams.sigproc_params = sigproc_params; 
        trialparams.plot_params = plot_params; 
        trialparams.event_params = event_params; 

        if ~isempty(output_emptyOst)
            firstMissingEvent = output_ost.eventNames{output_emptyOst(1)}; 
            fprintf('Missing output OST events including and after %s for trial %d\n', firstMissingEvent, itrial)
        end

        % Mark trial as bad if the trigger never happened
        if isempty(output_ost.indices.(ost.trigger))
            trialparams.event_params.is_good_trial = 0;
        end

        if trialparams.event_params.is_good_trial == 0 
            warning('Trial %d marked bad: no perturbation triggered.\n', itrial)
        end    

        % Save output structures into the trial file 
        if bSaveCheck, bSaveOut = savecheck(savefileout); else, bSaveOut = 1; end
        trialparams.event_params = output_event_params;
        if bSaveOut, save(savefileout,'sigmat','trialparams'); end

    end
    fprintf('Done\n')

end

if bBuffersOut
    varargout{1} = ost.eventLag; 
end

% Put the OST back to original if wanted
if bRefreshOst, refreshWorkingCopy(expt.name,stimWord,'ost'); end
fprintf('Saving data file... ')
save(fullfile(dataPath,'data.mat'),'data'); 
fprintf('Done\n')


    
end