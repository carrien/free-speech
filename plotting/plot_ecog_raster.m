function [ ] = plot_ecog_raster(neuralY,chnum,trialgroups,nrows,pos)
%PLOT_EGOG_RASTER  Plot a 2D matrix of ECOG activity for a given channel.
%   TRIALGROUPS is a struct array of trial vectors, one per plot.

if nargin < 4, nrows = 6; end % must be at least 2
%if nargin < 5, pos = [1434 187 560 1042]; end
if nargin < 5, pos = [109 39 560 732]; end

load('cmap');
cmaps = {cmap.g cmap.r cmap.b};
colors = {[.4 1 .4],[1 .4 .4],[.4 .4 1]};

if iscell(trialgroups)
    for i=1:length(trialgroups)
        fieldname = sprintf('field%02d',i);
        tg.(fieldname) = trialgroups{i};
    end
    trialgroups = tg;
elseif ~isstruct(trialgroups)
    error('Variable TRIALGROUPS must be a struct array or cell array.');
end

fns = fieldnames(trialgroups);

chdata = squeeze(neuralY(chnum,:,:))';
nplots = length(fns);
figure;
for i=1:nplots
    trialinds = trialgroups.(fns{i});
    subplot(nrows,nplots,i:nplots:(nrows-2)*nplots+i)
    %imagesc(chdata(trialinds,:));
    %subimage_tweak(chdata(trialinds,:),cmaps{i});
    imagesc(chdata(trialinds,:));
    title(fns{i})
    colormap(cmaps{i});
    freezeColors
    vline(100,'w','--');
    %subplot(nrows,nplots,(nrows-1)*nplots+i)
    subplot(nrows,nplots,(nrows-1)*nplots+1:nrows*nplots)
    plot(nanmean(chdata(trialinds,1:300)),'color',colors{i});
    hold on;
end
vline(100,'k');
set(gcf,'MenuBar','none')
set(gcf,'Position',pos)

end

