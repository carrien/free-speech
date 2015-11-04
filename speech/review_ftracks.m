function [ ] = review_ftracks(exptName,snum,subdirname,dataValsStr,gridsize)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end
if nargin < 4 || isempty(gridsize), gridsize = [6 3]; end

nperscreen = prod(gridsize);

load(fullfile(getAcousticSubjDir(exptName,snum,subdirname),dataValsStr))

figure;
for i=1:length(dataVals)
    trialnum = dataVals(i).token;
    load(fullfile(getAcousticSubjDir(exptName,snum,subdirname),trials),trialnum);
    
    % plot spectrogram
    
    hold on;
    plot(dataVals(i).ftrack_taxis,dataVals(i).f1,'b');
    plot(dataVals(i).ftrack_taxis,dataVals(i).f2,'r');
end
