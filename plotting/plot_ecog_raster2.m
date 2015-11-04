function [ ] = plot_ecog_raster2(neuralY,chnum,trialgroups,nrows,pos)
%PLOT_EGOG_RASTER  Plot a 2D matrix of ECOG activity for a given channel.
%   TRIALGROUPS is a struct array of trial vectors, one per plot.

if nargin < 4, nrows = 3; end % must be at least 2
if nargin < 5, pos = [109 39 1120 732]; end

red = [1 .4 .4];
green = [.4 1 .4];

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
    imagesc(chdata(trialinds,:));
    title(fns{i})
    vline(100,'w','--');
    subplot(nrows,nplots,(nrows-1)*nplots+i)
    % plot center
    sig = chdata(trialinds(1:ceil(length(trialinds)/3)),1:300);
    plot(nanmean(sig),'color',green,'LineWidth',2);
    hold on;
    err = get_errorbars(sig','se');
    plot_filled_err([],nanmean(sig),err',green);
    % plot periph
    sig = chdata(trialinds(ceil(2*length(trialinds)/3):end),1:300);
    plot(nanmean(sig),'color',red,'LineWidth',2);
    err = get_errorbars(sig','se');
    plot_filled_err([],nanmean(sig),err',red);
    vline(100,'k');
end
set(gcf,'MenuBar','none')
set(gcf,'Position',pos)

end

