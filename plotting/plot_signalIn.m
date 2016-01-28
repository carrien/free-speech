function [ ] = plot_signalIn(dataPath,nplots_per_fig)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, nplots_per_fig = 100; end

load(fullfile(dataPath,'data.mat'));
for h=0:nplots_per_fig:length(data)-1
    figure;
    for i=1:nplots_per_fig
        subplot(ceil(sqrt(nplots_per_fig)),ceil(sqrt(nplots_per_fig)),i)
        plot(data(h+i).signalIn)
        set(gca,'XTick',[]);
        set(gca,'YTick',[]);
    end
end

