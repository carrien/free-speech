function [ ] = check_audio_errors(dataPath,split,cond)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(split), split = 'words'; end
if nargin < 3 || isempty(cond), cond = 'eat'; end

load(fullfile(dataPath,'data.mat'));
load(fullfile(dataPath,'expt.mat'));

disp(cond);
trialnums = expt.inds.(split).(cond);
for t=1:length(trialnums)
    trialnum = trialnums(t);
    disp(trialnum);
    h = audioplayer(data(trialnum).signalIn,11025);
    playblocking(h);
    play_tone(500,.075);
    pause(.1);
end
