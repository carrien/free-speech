function [ ] = check_audio_errors(dataPath,grouping,groups,nbtrials,bExcl)
%CHECK_AUDIO_ERRORS  Listen to groups of trials to check for speech errors.
%   CHECK_AUDIO_ERRORS(DATAPATH,GROUPING,GROUPS,NBTRIALS,BEXCL)

if nargin < 1 || isempty(dataPath), dataPath = cd; end       % path to data
if nargin < 2 || isempty(grouping), grouping = 'words'; end  % grouping variable
if nargin < 4 || isempty(nbtrials), nbtrials = 10; end       % ntrials per block (before break)
if nargin < 5 || isempty(bExcl), bExcl = 1; end              % exclude bad trials or no

% load data
load(fullfile(dataPath,'data.mat'));
load(fullfile(dataPath,'expt.mat'));

if bExcl % remove bad trials
    load(fullfile(dataPath,'dataVals.mat'));
    excllog = [dataVals.bExcl];
    excl = [dataVals(excllog).token];
    trialAdjStr = 'good ';
else     % or keep them
    excl = [];
    trialAdjStr = '';
end

% if group is undefined, check all groups (e.g. all words)
if nargin < 3 || isempty(groups)
    groups = expt.(grouping);
elseif ischar(groups)  % if a single group is defined,
    groups = {groups}; % put it in an array
end

% get start trial
reply = input('Start trial? [1]: ','s');
if isempty(reply), reply = '1'; end
startTrial = sscanf(reply,'%d');

% loop over groups
fprintf('Press any key to begin; press CTRL-C at any time to quit.\n');
pause;
for g = 1:length(groups)
    group = groups{g};
    
    trials = expt.inds.(grouping).(group);
    trials = setdiff(trials,excl);
    trials = trials(trials >= startTrial);
    fprintf('%s (%d %strials)\n',group,length(trials),trialAdjStr);
    pause;
    
    for t=1:length(trials)
        trialnum = trials(t);
        fprintf('%d ',trialnum);
        h = audioplayer(data(trialnum).signalIn,data(trialnum).params.fs);
        playblocking(h);
        if nbtrials && ~mod(t,nbtrials)
            fprintf('\n');
            pause;
        else
            play_tone(500,.075,.25,[],1);
            pause(.1);
        end
    end
    
end
