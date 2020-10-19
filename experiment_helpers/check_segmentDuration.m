function expt = check_segmentDuration(expt)
% DATA = CHECK_AUDIO(dataPath,trialinds)
% Find the duration of segments (or parts of segments), based on OST status
% changes 
%Inputs:
%   dataPath: path where data.mat and expt.mat for the "pre" phase are. Default is current
%   directory

% if nargin < 1 || isempty(dataPath), dataPath = cd; end
dataPath = fullfile(expt.dataPath,expt.listWords{1},'pre'); 

% addpath('C:\Users\Public\Documents\software\current-studies\timeAdapt')

%% Load in data
fprintf('Loading trial data... ');
load(fullfile(dataPath,'data.mat'))
load(fullfile(dataPath,'expt.mat'))
fprintf('Done\n');

% Get the word
stimWord = expt.listWords{1}; 

% get number of trials
ntrials = expt.ntrials;

% Get sampling rates, etc. 
fs = expt.audapterParams.sr; 
frameLength = expt.audapterParams.frameLen; 
ostFactor = fs/frameLength; 

%% Set up OST recognition 
% Get the target OST values
if strcmp(stimWord,'god') || strcmp(stimWord,'gar')
    dummyWord = 'ada';   
elseif strcmp(stimWord,'cod') || strcmp(stimWord,'car')    
    dummyWord = 'ata';    
elseif strcmp(stimWord,'sea') || strcmp(stimWord,'C') || strcmp(stimWord,'saw')
    dummyWord = 'asa';     
elseif strcmp(stimWord,'czar') || strcmp(stimWord,'Z')
    dummyWord = 'aza';     
elseif contains(stimWord,'apper')
    dummyWord = stimWord; 
end

if strcmp(dummyWord,'ata') || strcmp(dummyWord,'capper')
    ostAdd = 4;
else
    ostAdd = 2; 
end
% ostAdd = 2; % I believe this is true for all cases now because we're not trying to hit an OST status for aspiration? 

% Get OST statuses that mark beginning and end of segment of interest
ostStatBegin = get_pcf(expt.name, dummyWord, 'ostStat_initial'); 
ostStatEnd = ostStatBegin + ostAdd; 

% Get the buffer amount for the ostStatBegin (so hand correction is more intuitive) 
ostWorking = ['C:\Users\Public\Documents\software\current-studies\timeAdapt\' dummyWord 'Working.ost'];
ostStatBeginPrev = ostStatBegin - 2; % this is currently true for all cases
ostStatEndPrev = ostStatEnd - 2; 

% If a working copy doesn't exist, make one
if exist(ostWorking,'file') ~= 2
    refreshWorkingCopy(dummyWord,'ost');
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

% ostStatBegin_line = find(strncmp(finfo, num2str(ostStatBegin), 1)); 
% cellfun(@(x) strncmp(x, num2str(ostStatPrev), 1), finfo, 'UniformOutput', 0);

% The additional lag will be the 4th element
ostStatBeginPrev_components = strsplit(finfo{strncmp(finfo, num2str(ostStatBeginPrev), 1)}, ' '); 
beginPrevHeur = ostStatBeginPrev_components{2}; 
% Unless you're using a stretch/span heuristic in which case it will be the number of frames in the 3rd component / framelen
if contains(beginPrevHeur,'STRETCH')
    ostStatBeginPrev_lag = str2double(ostStatBeginPrev_components{3}) / expt.audapterParams.frameLen; 
else
    ostStatBeginPrev_lag = str2double(ostStatBeginPrev_components{4}); 
end

% now again for the ending ost
ostStatEndPrev_components = strsplit(finfo{strncmp(finfo, num2str(ostStatEndPrev), 1)}, ' '); 
endPrevHeur = ostStatEndPrev_components{2}; 
if contains(endPrevHeur,'STRETCH')
    ostStatEndPrev_lag = str2double(ostStatEndPrev_components{3}) / expt.audapterParams.frameLen; 
else
    ostStatEndPrev_lag = str2double(ostStatEndPrev_components{4}); 
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
    segStartIx = find((ost_stat == ostStatBegin),1); 
    segEndIx = find((ost_stat == ostStatEnd),1); 
    
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
    event_params.user_event_times = [segBeginTimePlot segEndTimePlot];
    if strcmp(dummyWord,'capper') || strcmp(dummyWord,'gapper') || strcmp(dummyWord,'ada') || strcmp(dummyWord,'ata')
        uev1name = 'cBurst'; 
    else
        uev1name = 'cStart';
    end
    event_params.user_event_names = {uev1name 'vStart'}; 
    
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