function [ ] = check_audio_errors(dataPath,grouping,group,nbtrials)
%CHECK_AUDIO_ERRORS Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(grouping), grouping = 'words'; end
if nargin < 3 || isempty(group), group = 'eat'; end
if nargin < 4 || isempty(nbtrials), nbtrials = 0; end

load(fullfile(dataPath,'data.mat'));
load(fullfile(dataPath,'expt.mat'));

disp(group);
trials = expt.inds.(grouping).(group);
for t=1:length(trials)
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
