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
nObsPerCond = NaN(1,nConds);
for c=1:nConds
    cond = conds{c};
    nObsPerCond(c) = length(dataMeansByCond.(cond));
end

if sum(abs(diff(nObsPerCond)))
    warning('Different numbers of observations found across conditions. Treating data as unpaired.');
    p.bPaired = 0;
end

%% set default params
defaultParams.Marker = '.';
defaultParams.MarkerSize = 25;
defaultParams.MarkerAlpha = .25;
defaultParams.avgMarker = 'o';
defaultParams.avgMarkerSize = 12;
defaultParams.avgMarkerColor = colorSpec;
defaultParams.LineColor = [.7 .7 .7];
defaultParams.LineWidth = 1;
defaultParams.avgLineColor = colorSpec; %[0 0 0]
defaultParams.avgLineWidth = 3;
defaultParams.jitterFrac = 0.25;
defaultParams.bCI = 0;
defaultParams.capsize = 10;
defaultParams.bPaired = 1;
defaultParams.bMeansOnly = 0;
p = set_missingFields(p,defaultParams,0);

defaultParams.avgErrorColor = p.avgMarkerColor; % default: same as marker color
p = set_missingFields(p,defaultParams,0);

%% colors
if iscell(colorSpec(1)) %if colors are specified as character strings
    warning('Colors must be entered as RBG values, not character strings.')
    warning('Plotting with default colors.')
    colorSpec = [0 0 0];
else % if colors are specified as RBG values
    nColors = size(colorSpec,1);
    nAvgColors = size(p.avgMarkerColor,1);
end
if nColors == 1 || nColors~=nConds
    if nColors > 1
        warning('Number of colors does not match number of conditions. Using single color for plotting.')
    end
    colorSpec = repmat(colorSpec,nConds,1);
end
if nAvgColors == 1 || nColors~=nConds
    if nAvgColors > 1
        warning('Number of colors for averages does not match number of conditions. Using single color for plotting.')
    end
    p.avgMarkerColor = repmat(p.avgMarkerColor,nConds,1);
end

%% check that data is in the right orientation
for c=1:nConds
    cond = conds{c};
    condSize = size(dataMeansByCond.(cond));
    if condSize(1) == 1
        dataMeansByCond.(cond) = dataMeansByCond.(cond)';
    end
end

%% plot

h = figure;
hold on;

cond_means = zeros(length(dataMeansByCond.(conds{1})),length(conds));
cond_se = zeros(length(dataMeansByCond),length(conds));
cond_ci = zeros(length(dataMeansByCond),length(conds));

if ~p.bMeansOnly
    %set jitters
    if p.jitterFrac
        fixedJitters = (rand(max(nObsPerCond),1)-0.5)*p.jitterFrac; %set jitters for use in paired plots
        for c = 1:nConds
            cond = conds{c};
            if p.bPaired
                jitters.(cond) = fixedJitters;
            else
                jitters.(cond) = (rand(nObsPerCond(c),1)-0.5)*p.jitterFrac;
            end
        end
    end
    
    % lines
    if p.bPaired
        for c=1:nConds-1
            cond = conds{c}; nextcond = conds{c+1};
            if p.jitterFrac
                for o=1:nObsPerCond(c)
                    plot([c c+1]+jitters.(cond)(o),[dataMeansByCond.(cond)(o) dataMeansByCond.(nextcond)(o)],'-','Color',p.LineColor,'LineWidth',p.LineWidth);
                end
            else
                plot([c c+1],[dataMeansByCond.(cond) dataMeansByCond.(nextcond)],'-','Color',p.LineColor,'LineWidth',p.LineWidth);
            end
        end
    end
    
    % dots
    for c=1:nConds
        cond = conds{c};
        cond_data = dataMeansByCond.(cond);
        
        if p.jitterFrac
            scatter(c+jitters.(cond),cond_data,p.MarkerSize,'MarkerFaceColor',get_lightcolor(colorSpec(c,:)),'MarkerFaceAlpha',p.MarkerAlpha,'MarkerEdgeColor','none')
        else
            plot(c,cond_data,p.Marker,'Color',get_lightcolor(colorSpec(c,:)),'MarkerSize',p.MarkerSize)
        end
    end
end

% average data and errorbars
hold on
if p.bPaired
    for c=1:nConds
        cond = conds{c};
        cond_means(:,c) = dataMeansByCond.(cond);
    end
  plot(1:nConds,nanmean(cond_means,1),'-','Color',p.avgLineColor,'LineWidth',p.avgLineWidth)   
end
for c = 1:nConds
    cond = conds{c};
    cond_data = dataMeansByCond.(cond);
    cond_se(c) = nanstd(cond_data,0,1) / sqrt(length(cond_data));
    cond_ci(c) = calcci(cond_data');
    plot(c,nanmean(cond_data),p.avgMarker,'Color',p.avgMarkerColor(c,:),'MarkerFace',p.avgMarkerColor(c,:),'MarkerSize',p.avgMarkerSize)
    if p.bCI
        errorbar(c,nanmean(cond_data), cond_ci(c),'Color',p.avgMarkerColor(c,:),'LineWidth',p.avgLineWidth,'CapSize',p.capsize)
    else
        errorbar(c,nanmean(cond_data), cond_se(c),'Color',p.avgMarkerColor(c,:),'LineWidth',p.avgLineWidth,'CapSize',p.capsize)
%         errorbar(c,nanmean(cond_data), cond_ci(c),'Color',p.avgErrorColor(c,:),'LineWidth',p.avgLineWidth)
%     else
%         errorbar(c,nanmean(cond_data), cond_se(c),'Color',p.avgErrorColor(c,:),'LineWidth',p.avgLineWidth)
    end
end

set(gca,'XTick',1:nConds,'XTickLabel',conds)
%YTick = get(gca,'YTick');
%set(gca,'YTick',min(YTick):200:max(YTick))
ax = axis;
axis([.5 nConds+.5 ax(3) ax(4)])
