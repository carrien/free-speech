function [h] = plot_pairedData(dataMeansByCond,colorSpec,p)
%PLOT_PAIREDDATA  Plots mean data connected by lines across conditions.
%   PLOT_PAIREDDATA(DATAMEANSBYCOND, COLORSPEC)

if nargin < 2 || isempty(colorSpec)
    colorSpec = [0 0 0];
end
if nargin < 3, p = struct; end

%% validate equal number of data points per condition
conds = fieldnames(dataMeansByCond);
nConds = length(conds);
for c=1:nConds
    cond = conds{c};
    if ~exist('nObsPerCond','var')
        nObsPerCond = length(dataMeansByCond.(cond));
    elseif nObsPerCond ~= length(dataMeansByCond.(cond))
        warning('Different numbers of observations found across conditions.');
    end
end

%% set params

% TODO: add defaults
% p.Marker = '.';
% p.MarkerSize = 12;
% p.LineWidth = 1;
% p.avgMarker = 'o';
% p.avgMarkerSize = 8;
% p.avgLineWidth = 3;
p.avgLineColor = [0 0 0];

%% colors
if iscell(colorSpec(1)) %if colors are specified as character strings
    warning('Colors must be entered as RBG values, not character strings.')
    warning('Plotting with default colors.')
    colorSpec = [0 0 0];
else % if colors are specified as RBG values
    nColors = size(colorSpec,1);
end
if nColors == 1 || nColors~=nConds
    if nColors > 1
        warning('Number of colors does not match number of conditions. Using single color for plotting.')
    end
    colorSpec = repmat(colorSpec,nConds,1);
end

%% plot

h = figure;
hold on;

cond_means = zeros(length(dataMeansByCond.(conds{1})),length(conds));
cond_ses = zeros(length(dataMeansByCond),length(conds));

if p.jitterFrac
    jitters = (rand(nObsPerCond,1)-0.5)*p.jitterFrac;
end

% lines
for c=1:nConds-1
    cond = conds{c}; nextcond = conds{c+1};
    if p.jitterFrac
        for o=1:nObsPerCond
            plot([c c+1]+jitters(o),[dataMeansByCond.(cond)(o) dataMeansByCond.(nextcond)(o)],'-','Color',p.LineColor,'LineWidth',p.LineWidth);
        end
    else
        plot([c c+1],[dataMeansByCond.(cond)' dataMeansByCond.(nextcond)'],'-','Color',p.LineColor,'LineWidth',p.LineWidth);
    end
end

% dots
for c=1:nConds
    cond = conds{c};
    cond_data = dataMeansByCond.(cond)';

    cond_means(:,c) = cond_data;
    %cond_ses(:,c) = nanstd(cond_data,0,1) / sqrt(length(cond_data));
    cond_se(c) = nanstd(cond_data,0,1) / sqrt(length(cond_means(:,c)));
    cond_ci(c) = calcci(cond_data');
    if p.jitterFrac
        %plot(c+jitters,dataMeansByCond.(cond),p.Marker,'Color',get_lightcolor(colorSpec(c,:)),'MarkerSize',p.MarkerSize)
        scatter(c+jitters,dataMeansByCond.(cond),p.MarkerSize,'MarkerFaceColor',get_lightcolor(colorSpec(c,:)),'MarkerFaceAlpha',p.MarkerAlpha,'MarkerEdgeColor','none')
    else
        plot(c,dataMeansByCond.(cond),p.Marker,'Color',get_lightcolor(colorSpec(c,:)),'MarkerSize',p.MarkerSize)
    end
end

% average data and errorbars
hold on
plot(1:nConds,nanmean(cond_means,1),'-','Color',p.avgLineColor,'LineWidth',p.avgLineWidth)
for c = 1:nConds
    plot(c,nanmean(cond_means(:,c)),p.avgMarker,'Color',colorSpec(c,:),'MarkerFace',colorSpec(c,:),'MarkerSize',p.avgMarkerSize)
    errorbar(c,nanmean(cond_means(:,c)), cond_ci(c),'Color',colorSpec(c,:),'LineWidth',p.avgLineWidth)
end

set(gca,'XTick',1:nConds,'XTickLabel',conds)
%YTick = get(gca,'YTick');
%set(gca,'YTick',min(YTick):200:max(YTick))
ax = axis;
axis([.5 nConds+.5 ax(3) ax(4)])
