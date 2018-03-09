function [ ] = check_audio_errors(dataPath,grouping,group,nbtrials,bExcl)
%CHECK_AUDIO_ERRORS  Listen to groups of trials to check for speech errors.
%   CHECK_AUDIO_ERRORS(DATAPATH,GROUPING,GROUP,NBTRIALS,BEXCL) 

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(grouping), grouping = 'words'; end
if nargin < 3 || isempty(group), group = 'eat'; end
if nargin < 4 || isempty(nbtrials), nbtrials = 10; end
if nargin < 5 || isempty(bExcl), bExcl = 1; end

reply = input('Start trial? [1]: ','s');
if isempty(reply), reply = '1'; end
startTrial = sscanf(reply,'%d');

load(fullfile(dataPath,'data.mat'));
load(fullfile(dataPath,'expt.mat'));

disp(group);
trials = expt.inds.(grouping).(group);

if bExcl % remove bad trials
    load(fullfile(dataPath,'dataVals.mat'));
    excllog = [dataVals.bExcl];
    excl = dataVals(excllog).token;
    trials = setdiff(trials,excl);
end

for t=startTrial:length(trials)
    trialnum = trials(t);
    disp(trialnum);
    h = audioplayer(data(trialnum).signalIn,data(trialnum).params.fs);
    playblocking(h);
    if nbtrials && ~mod(t,nbtrials)
        pause;
    else
        play_tone(500,.075,[],[],1);
        pause(.1);
    end
end
