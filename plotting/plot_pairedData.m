function [h] = plot_pairedData(dataMeansByCond, colorSpec)
% plotMeanStroopRT(reaction_times)
% This function creates a plot of the mean reaction time by condition for
% the Stroop conditions (congruent, incongruent vowel, and incongruent
% color).
%
% INPUT:
% reaction_times: This is a structure containing the reaction time data. It
% is generated as output by the function calc_RT.m
if nargin < 2 || isempty(colorSpec)
    colorSpec = [0 0 0];
end

conds = fieldnames(dataMeansByCond);
nConds = length(conds);

%get number of colors and check if they match number of conditions
if iscell(colorSpec(1)) %if colors are specified as character strings
    warning('Colors must be entered as RBG values, not character strings.')
    warning('Plotting with default colors.')
    colorSpec = [0 0 0];
else % if colors are specified as RBG values
    nColors = size(colorSpec,1);
end
if nColors == 1 || nColors~=nConds
    if nColors ~= nConds
        warning('Number of colors does not match number of conditions. Using single color for plotting.')
    end
    colorSpec = repmat(colorSpec,nConds,1);
end


cond_data = cell(1,length(conds));
cond_means = zeros(length(dataMeansByCond.(conds{1})),length(conds));
cond_ses = zeros(length(dataMeansByCond),length(conds));

% Make a bar plot of the mean reaction times
h = figure;
%bar(nanmean(cond_means,1));

hold on;

% individual subject data
subjColor = colorSpec + 0.4;
subjColor(subjColor > 1) = 1;
lineColor = .7*ones(1,3);
% subjColor = .7*ones(1,3);
subjMarkerSize = 12;

% lines
for c=1:nConds-1
    cond = conds{c}; nextcond = conds{c+1};
    plot([c c+1],[dataMeansByCond.(cond)' dataMeansByCond.(nextcond)'],'-','Color',lineColor,'LineWidth',1);
end

% dots
for c=1:nConds
    cond = conds{c};
    cond_data = dataMeansByCond.(cond)';

    cond_means(:,c) = cond_data;
    %cond_ses(:,c) = nanstd(cond_data,0,1) / sqrt(length(cond_data));
    cond_se(c) = nanstd(cond_data,0,1) / sqrt(length(cond_means(:,c)));
    cond_ci(c) = calcci(cond_data');
    plot(c,dataMeansByCond.(cond),'.','Color',subjColor(c,:),'MarkerSize',subjMarkerSize)
end



% average data and errorbars
hold on
avgColor = [0 0 0]; %[.2 0 .5];
avgMarkerSize = 8;
plot(1:nConds,nanmean(cond_means,1),'-','Color',avgColor,'LineWidth',3)
for c = 1:nConds
    plot(c,nanmean(cond_means(:,c)),'o','Color',colorSpec(c,:),'MarkerFace',colorSpec(c,:),'MarkerSize',avgMarkerSize)
    errorbar(c,nanmean(cond_means(:,c)), cond_ci(c),'Color',colorSpec(c,:),'LineWidth',3)
%     plot(1:size(cond_means,2),nanmean(cond_means,1),'o','Color',avgColor,'MarkerFace',avgColor,'MarkerSize',avgMarkerSize)
end

%errorbar(nanmean(cond_means,1), nanmean(cond_ses,1),'Color',avgColor,'LineWidth',3);
%errorbar(nanmean(cond_means,1), cond_se,'Color',avgColor,'LineWidth',3);
% errorbar(nanmean(cond_means,1), cond_ci,'Color',avgColor,'LineWidth',3);
set(gca,'XTick',1:nConds,'XTickLabel',conds)
%YTick = get(gca,'YTick');
%set(gca,'YTick',min(YTick):200:max(YTick))
ax = axis;
axis([.5 nConds+.5 ax(3) ax(4)])
makeFig4Screen;
