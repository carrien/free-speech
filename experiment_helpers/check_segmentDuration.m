function expt = check_segmentDuration(expt, startStatus, endStatus, uevent1name, uevent2name)
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
% if nargin < 1 || isempty(dataPath), dataPath = cd; end
dataPath = fullfile(expt.dataPath,expt.listWords{1},'pre'); % This should probably be made better. 

% Get the word
stimWord = expt.listWords{1}; 
% Get the target OST values
if strcmp(stimWord,'god') || strcmp(stimWord,'gar')
    expt.trackingFileName = 'ada';   
elseif strcmp(stimWord,'cod') || strcmp(stimWord,'car')    
    expt.trackingFileName = 'ata';    
elseif strcmp(stimWord,'sea') || strcmp(stimWord,'C') || strcmp(stimWord,'saw')
    expt.trackingFileName = 'asa';     
elseif strcmp(stimWord,'czar') || strcmp(stimWord,'Z')
    expt.trackingFileName = 'aza';     
elseif contains(stimWord,'apper')
    expt.trackingFileName = stimWord; 
end

% If startStatus empty, get the triggering one
if nargin < 2 || isempty(startStatus)
    startStatus = get_pcf(expt.trackingFileLoc, expt.trackingFileName, 'time', '1', 'ostStat_initial'); % Get the triggering status
end
% If endStatus empty, get the one immediately after startStatus
if nargin < 3 || isempty(endStatus)
    if strcmp(expt.trackingFileName,'ata') || strcmp(expt.trackingFileName,'capper')
        ostAdd = 4;
    else
        ostAdd = 2; 
    end
    endStatus = startStatus + ostAdd; 
end

if nargin < 4 || isempty(uevent1name), uevent1name = 'segStart'; end
if nargin < 5 || isempty(uevent2name), uevent2name = 'segEnd'; end

%%
% Load in data
fprintf('Loading trial data... ');
load(fullfile(dataPath,'data.mat'))
% load(fullfile(dataPath,'expt.mat')) % RK 02/02/2021: why is this here? aren't you loading in the expt in the
% args? 
fprintf('Done\n');

% get number of trials
ntrials = expt.ntrials;

% Get sampling rates, etc. 
fs = expt.audapterParams.sr; 
frameLength = expt.audapterParams.frameLen; 
ostFactor = fs/frameLength; 

%% Set up OST recognition 
% Get the buffer amount for the ostStatBegin (so hand correction is more intuitive) 
ostWorking = fullfile(get_gitPath, 'current-studies', expt.trackingFileLoc, [expt.trackingFileName 'Working.ost']); 
ostStatBeginPrev = startStatus - 2; % this is currently true for all cases
ostStatEndPrev = endStatus - 2; 

% If a working copy doesn't exist, make one
if exist(ostWorking,'file') ~= 2
    refreshWorkingCopy(expt.trackingFileLoc, expt.trackingFileName, 'ost');
end

% Open file and load file line by line into structure finfo
fid = fopen(ostWorking,'r');
tline = fgetl(fid);
itrial = 1;
clear finfo
finfo{itrial} = tline;
while ischar(tline)
    itrial = itrial+1;
    tline = fgetl(fid);
    finfo{itrial} = tline;
end
fclose(fid);

% Lags induced by status waiting for the appropriate amount of either time or frames
[preStartStatHeur, ~, preStartStatParam2] = get_ost(expt.trackingFileLoc, expt.trackingFileName, startStatus-2); 
% Unless you're using a stretch/span heuristic in which case it will be the number of frames in the 3rd component / framelen
if contains(preStartStatHeur,'STRETCH')
    ostStatBeginPrev_lag = preStartStatParam2 * expt.audapterParams.frameLen / expt.audapterParams.sr; 
else
    ostStatBeginPrev_lag = preStartStatParam2; 
end

% now again for the ending ost
[preEndStatHeur, ~, preEndStatParam2] = get_ost(expt.trackingFileLoc, expt.trackingFileName, endStatus-2); 
if contains(preEndStatHeur,'STRETCH')
    ostStatEndPrev_lag = preEndStatParam2 * expt.audapterParams.frameLen / expt.audapterParams.sr; 
else
    ostStatEndPrev_lag = preEndStatParam2; 
end


%% Create user event times

trialfolder = 'trials'; 
if ~exist(fullfile(dataPath,trialfolder), 'dir') % 
    mkdir(fullfile(dataPath,trialfolder))
end

for itrial = 1:ntrials
    % Set up savepaths 
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial));
    
    % Assume that nothing exists. It's fine for now...   
    sigproc_params = get_sigproc_defaults;
    plot_params = get_plot_defaults;
    plot_params.hzbounds4plot = [0 10000]; % to find s/z noise more easily 
    
    event_params = get_event_defaults;
    sigmat = [];
    trialparams = struct(); 
    
    % Find start and end times of segment of interest
    ost_stat = data(itrial).ost_stat; 
    segStartIx = find((ost_stat == startStatus),1); 
    segEndIx = find((ost_stat == endStatus),1); 
    
    % if the right osts failed to trigger
    if ~isempty(segStartIx)
        segStartTime = segStartIx/ostFactor;         
    else 
        segStartTime = (length(ost_stat)/2)/ostFactor; % arbitrarily picking midpoint of the file
        fprintf('OST didn''t trigger: trial %d\n',itrial); 
    end    
    if ~isempty(segEndIx)
        segEndTime = segEndIx/ostFactor; 
    else
        segEndTime = segStartTime + 0.05; % can't define this totally arbitrarily because it has to be after startSegTime regardless of the existence of startSegIx
        fprintf('No status change after trigger: trial %d\n',itrial); 
    end
    
    % The start will have to be PLOTTED at a different time to visually account for the lag in detecting (burst, etc.) 
    segBeginTimePlot = segStartTime - ostStatBeginPrev_lag; 
    segEndTimePlot = segEndTime - ostStatEndPrev_lag; 
    
    % Generate trialparams and sigmat??? 
    % Might be able to put this info in the OST file itself... 
    event_params.user_event_times = [segBeginTimePlot segEndTimePlot];
    if strcmp(expt.trackingFileName,'capper') || strcmp(expt.trackingFileName,'gapper') || strcmp(expt.trackingFileName,'ada') || strcmp(expt.trackingFileName,'ata')
        uevent1name = 'cBurst'; 
        uevent2name = 'vStart'; 
    elseif strcmp(expt.trackingFileName, 'sapper') || strcmp(expt.trackingFileName, 'zapper')
        uevent1name = 'cStart';
        uevent2name = 'vStart'; 
    end
    event_params.user_event_names = {uevent1name uevent2name}; 
    
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
    
    % do a gen_dataVals? 
    avail2perturb = [];
    goodTokens = 0; 
    for itrial = 1:ntrials
        load(fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial))); 
        if trialparams.event_params.is_good_trial
            segStartTime = trialparams.event_params.user_event_times(1); 
            segEndTime = trialparams.event_params.user_event_times(2); 
        
            % Readjust the time for the amount of time that you ACTUALLY have available to you for warping purposes 
            segStartTime_readjust = segStartTime + ostStatBeginPrev_lag; 
            segEndTime_readjust = segEndTime + ostStatEndPrev_lag;      
        
            avail2perturb(itrial) = segEndTime_readjust - segStartTime_readjust; 
            goodTokens = goodTokens + 1; 
        else
            avail2perturb(itrial) = NaN; 
        end
        
    end
    
    % spit out values 
    availMean = nanmean(avail2perturb); 
    availMax = nanmax(avail2perturb); 
    availSd = nanstd(avail2perturb); 
    
    % put them into expt.durHoldMax
    durHoldMax = availMean + (2*availSd);
    expt.durHoldMax = durHoldMax;
    expt.goodTokens = goodTokens; 
    expt.avail2perturb = avail2perturb; 
    
end