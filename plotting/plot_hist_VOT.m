function [ ] = plot_hist_VOT(dataPath,color,wordinds)
%PLOT_HIST_VOT  Plot voice onset time histogram.
%   PLOT_HIST_VOT(DATAPATH,GROUPING) plots histograms of voice onset time
%   for each group in GROUPING (e.g. 'word' or 'cond').

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(color), color = 'pink'; end

% load data
load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,'dataVals.mat'));

% get trials of given color
trialinds = expt.inds.colors.(color);
dataVals = dataVals(trialinds);
allWords = [dataVals.word];
if nargin < 3 || isempty(wordinds)
    colorind = find(strcmp(expt.words,color));
    wordinds = [colorind colorind+1];
end

% set plot params
colors = stroop_setcolors;
if startsWith(color,{'p' 't' 'k'})
    edges = 0:.005:.15;
elseif startsWith(color,{'b' 'd' 'g'})
    edges = -.05:.005:.1;
else
    error('Color must start with a stop consonant.')
end
vots = cell(1,length(wordinds));
plotcolor = cell(1,length(wordinds));

% plot histogram
figure;
for w=wordinds
    inds = allWords==w;
    vots{w} = [dataVals(inds).vot];
    plotcolor{w} = colors.(expt.words{w});
    switch w
        case 1
            facealpha = 1;
        otherwise
            facealpha = .75;
    end
    histogram(vots{w},edges,'FaceColor',plotcolor{w},'FaceAlpha',facealpha,'EdgeColor',plotcolor{w}) 
    hold on;
    xlabel('VOT (s)')
    ylabel('#')
    box off;
    makeFig4Screen;
end

for w=wordinds
    vline(nanmean(vots{w}),plotcolor{w});
end

title(sprintf('%s',color))
legend(expt.words(wordinds))


end

function [colors] = stroop_setcolors()
colors.rid = [1 .3 0];
colors.red = [1 0 0];
colors.rad = [.7 0 .4];

colors.grin = [.6 .8 0];
colors.green = [.5 .8 .2];
colors.grain = [0 .7 .5];

colors.bleed = [.2 .6 .8];
colors.blue = [0 0 1];
colors.blow = [.3 0 .8];

%colors.pink = [.9137 0 1];
colors.pink = [.8 0 .8];
%colors.bink = [.3189 0 .349];
colors.bink = [.2 0 .7];
colors.plue = [0 0 .3922];
colors.kreen = [.2471 .4 .098];
end