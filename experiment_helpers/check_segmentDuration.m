function expt = check_segmentDuration(expt, data, statuses, ueventNames, durationNames, origCalc)
% Find the duration of segments (or parts of segments), based on OST status changes 
% Inputs: 
% 1. expt: the expt that you are currently working with. Should provide information about tracking file
% location, name, and the data path (trials are loaded from this path) 
% 2. startStatus (added 2021/02/02): the OST status that marks the beginning of the segment(s) of interest
% --- defaults to the trigger status as fetched from the first time warping line from the PCF file
% 3. endStatus (added 2021/02/02): the OST status that marks the end of the segment(s) of interest
% --- defaults to startStatus + 2
% 4. uevent1name (added 2021/02/02): optional user event name for the startStatus
% 5. uevent2name (added 2021/02/02); optional user event name for the endStatus

% 
% Major change: RK 2021/02/02
% - Now allows flexibility with WHICH statuses you want to use, using two input arguments: 
% --- startStatus: the beginning of the interval of interest (given as an OST status number)
% --- endStatus: the end of the interval of interest (given as an OST status number)

%%
if strcmp(expt.name, 'timeAdapt')
    dataPath = fullfile(expt.dataPath,expt.listWords{1},'pre'); % This should probably be made better. 
else
    dataPath = expt.dataPath; 
end

if nargin < 2 || isempty(data)
    fprintf('Loading trial data... ');
    load(fullfile(dataPath,'data.mat'))
    fprintf('Done\n');
end

if nargin < 3 || isempty(statuses)
    startStatus = get_pcf(expt.trackingFileLoc, expt.trackingFileName, 'time', '1', 'ostStat_initial'); % Get the triggering status
    endStatus = startStatus + 2; 
    statuses = [startStatus endStatus]; 
end

nStatusPairs = length(statuses) - 1; 
if nStatusPairs < 1
    warning('Attempting to get a duration with only one endpoint. Stopping script'); 
    return
end

% Names for the audiogui events
if nargin < 4 || isempty(ueventNames)
    for i = 1:length(statuses)
        ueventNames{i} = ['status' statuses(i)]; 
    end
end

if nargin < 5 || isempty(durationNames)
    for i = 1:nStatusPairs
        durationNames{i} = ['duration_ost' num2str(statuses(i)) '_' num2str(statuses(i+1))]; 
    end
end

if nargin < 6 || isempty(origCalc), origCalc = 'orig'; end

%% Tracking file information

if isfield(expt, 'trackingFileLoc')
    trackingFileDir = expt.trackingFileLoc; 
elseif isfield(expt, 'trackingFileDir')
    trackingFileDir = expt.trackingFileDir; 
else
    trackingFileDir = 'experiment_helpers'; 
end 

% Get the word
stimWord = expt.listWords{1}; 
% Get the target OST values
if isfield(expt, 'trackingFileName')
    trackingFileName = expt.trackingFileName; 
elseif strcmp(stimWord,'god') || strcmp(stimWord,'gar')
    trackingFileName = 'ada';   
    expt.trackingFileName = trackingFileName;  
elseif strcmp(stimWord,'cod') || strcmp(stimWord,'car')    
    trackingFileName = 'ata';    
    expt.trackingFileName = trackingFileName;
elseif strcmp(stimWord,'sea') || strcmp(stimWord,'C') || strcmp(stimWord,'saw')
    trackingFileName = 'asa';     
    expt.trackingFileName = trackingFileName;  
elseif strcmp(stimWord,'czar') || strcmp(stimWord,'Z')
    trackingFileName = 'aza';     
    expt.trackingFileName = trackingFileName;  
elseif contains(stimWord,'apper')
    trackingFileName = stimWord; 
    expt.trackingFileName = trackingFileName; 
end

% If a working copy doesn't exist, make one
if strcmp(trackingFileDir, 'experiment_helpers')
    leadingDir = 'free-speech'; 
else
    leadingDir = 'current-studies'; 
end
ostWorking = fullfile(get_gitPath, leadingDir, trackingFileDir, [trackingFileName 'Working.ost']); 
if exist(ostWorking,'file') ~= 2
    refreshWorkingCopy(trackingFileDir, trackingFileName, 'ost');
end

%%
% get number of trials
ntrials = length(data); 

% Get sampling rates, etc. 
fs = expt.audapterParams.sr; 
frameLength = expt.audapterParams.frameLen; 
ostFactor = fs/frameLength; 

%% Call get_segmentDuration 

for s = 1:nStatusPairs
    durInfo(s,:) = get_segmentDuration(expt, data, statuses(s), statuses(s+1), origCalc); 
end

% This creates a structure where the second dimension is number of trials and the first is number of status pairs


%% Create user event times

trialfolder = 'trials'; 
if ~exist(fullfile(dataPath,trialfolder), 'dir') % 
    mkdir(fullfile(dataPath,trialfolder))
end

for itrial = 1:ntrials
    % Set up savepaths 
    if isfield(data, 'trial')
        trialno = data(itrial).trial; 
    else
        trialno = itrial; 
    end
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',trialno));
    
    % Assume that nothing exists. It's fine for now...   
    sigproc_params = get_sigproc_defaults;
    plot_params = get_plot_defaults;
    plot_params.hzbounds4plot = [0 10000]; % to find s/z noise more easily 
    
    event_params = get_event_defaults;
    sigmat = [];
    trialparams = struct();     
    trialparams.event_params.is_good_trial = sum([durInfo(:,itrial).bBadTrack]); % Can change this if you want when you're segmenting
    
    % First event---first row
    ueventTime = zeros(1, length(statuses)); 
    eventBuffer = zeros(1, length(statuses)); 
    
    ueventTime(1) = durInfo(1,itrial).adjusted_startStatusTime; 
    eventBuffer(1) = durInfo(1,itrial).startStatusTime - durInfo(1,itrial).adjusted_startStatusTime; 
    if isnan(ueventTime(1))
        ueventTime(1) = 0.50; % arbitrarily picking 500 ms
        eventBuffer(1) = 0; 
        fprintf('OST status %d didn''t trigger on trial %d\n',statuses(1), trialno);
    end
    
    % Use the end time from both rows for all other events
    for s = 1:nStatusPairs
        ueventTime(s+1) = durInfo(s, itrial).adjusted_endStatusTime; 
        eventBuffer(s+1) = durInfo(s,itrial).endStatusTime - durInfo(s,itrial).adjusted_endStatusTime;
        if isnan(ueventTime(s+1))
            ueventTime(s+1) = ueventTime(s) + 0.025; % arbitrarily adding 25 ms to previous status
            eventBuffer(s+1) = 0; 
            fprintf('OST status %d didn''t trigger on trial %d\n',statuses(1), trialno);
        end
    end
 
    % Put into into event_params 
    event_params.user_event_times = ueventTime;
    if strcmp(expt.name, 'timeAdapt')
        if strcmp(expt.trackingFileName,'capper') || strcmp(expt.trackingFileName,'gapper') || strcmp(expt.trackingFileName,'ada') || strcmp(expt.trackingFileName,'ata')
            ueventNames = {'cBurst' 'vStart'}; 
        elseif strcmp(expt.trackingFileName, 'sapper') || strcmp(expt.trackingFileName, 'zapper')
            ueventNames = {'cStart' 'vStart'}; 
        end
    end
    event_params.user_event_names = ueventNames; 
    
    trialparams.sigproc_params = sigproc_params; 
    trialparams.plot_params = plot_params; 
    trialparams.event_params = event_params; 
    
    % Save structures into the trial file
    save(savefile,'sigmat','trialparams')  
    
end

%% Open audioGUI 
    % Show audioGUI to adjust
    audioGUI(dataPath,[1:ntrials],'signalIn',[],0); % 0 for no savecheck (yes, you want to overwrite every time) 
    % check for two events, if there are any then open those in audioGUI 
    
    % Generate vector of true durations and available durations
    availableDur = nan(nStatusPairs, ntrials); 
    trueDur = nan(nStatusPairs, ntrials);  
    goodTokens = 0; 
    for itrial = 1:ntrials
        load(fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial))); 
        bInclude(s, itrial) = trialparams.event_params.is_good_trial; 
        
        for s = 1:nStatusPairs
            % Get pairs of event times, adjust the starting one by putting the buffer back 
            startTime = trialparams.event_params.user_event_times(s); 
            endTime = trialparams.event_params.user_event_times(s+1); 
            adjusted_startTime = startTime + eventBuffer(s); 

            if trialparams.event_params.is_good_trial
                availableDur(s, itrial) = endTime - adjusted_startTime; 
                trueDur(s, itrial) = endTime - startTime; 
            else
                availableDur(s, itrial) = NaN; 
                trueDur(s, itrial) = NaN; 
            end
        end

        for o = 1:length(statuses)
            if trialparams.event_params.is_good_trial
                correctedTime.(ueventNames{o})(itrial) = trialparams.event_params.user_event_times(o); 
            else
                availableDur(s, itrial) = NaN; 
                correctedTime.(ueventNames{o})(itrial) = NaN; 
            end

        end
        goodTokens = goodTokens + 1; 
            
        
    end
   
    % put them into expt
    for s = 1:nStatusPairs
        intervalName = durationNames{s}; 
        expt.availableDur.(intervalName) = availableDur(s,:); 
        expt.trueDur.(intervalName) = trueDur(s,:); 
        expt.bGoodToken.(intervalName) = bInclude(s,:); 
        
    end
    expt.correctedTime = correctedTime; 
    expt.goodTokens = goodTokens; 

    
end