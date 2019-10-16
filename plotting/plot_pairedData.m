function [h] = plot_pairedData(dataMeansByCond)
% plotMeanStroopRT(reaction_times)
% This function creates a plot of the mean reaction time by condition for
% the Stroop conditions (congruent, incongruent vowel, and incongruent
% color).
%
% INPUT:
% reaction_times: This is a structure containing the reaction time data. It
% is generated as output by the function calc_RT.m

conds = fieldnames(dataMeansByCond);

cond_data = cell(1,length(conds));
cond_means = zeros(length(dataMeansByCond.(conds{1})),length(conds));
cond_ses = zeros(length(dataMeansByCond),length(conds));

% Make a bar plot of the mean reaction times
h = figure;
%bar(nanmean(cond_means,1));

hold on;

% individual subject data
subjColor = .7*ones(1,3);
subjMarkerSize = 12;

% dots
for c=1:length(conds)
    cond = conds{c};
    cond_data = dataMeansByCond.(cond)';

    cond_means(:,c) = cond_data;
    %cond_ses(:,c) = nanstd(cond_data,0,1) / sqrt(length(cond_data));
    cond_se(c) = nanstd(cond_data,0,1) / sqrt(length(cond_means(:,c)));
    cond_ci(c) = calcci(cond_data');
    plot(c,dataMeansByCond.(cond),'.','Color',subjColor,'MarkerSize',subjMarkerSize)
end

% lines
for c=1:length(conds)-1
    cond = conds{c}; nextcond = conds{c+1};
    plot([c c+1],[dataMeansByCond.(cond)' dataMeansByCond.(nextcond)'],'-','Color',subjColor,'LineWidth',1);
end

% average data and errorbars
hold on
avgColor = [0 0 0]; %[.2 0 .5];
avgMarkerSize = 8;
plot(1:size(cond_means,2),nanmean(cond_means,1),'o','Color',avgColor,'MarkerFace',avgColor,'MarkerSize',avgMarkerSize)
%errorbar(nanmean(cond_means,1), nanmean(cond_ses,1),'Color',avgColor,'LineWidth',3);
%errorbar(nanmean(cond_means,1), cond_se,'Color',avgColor,'LineWidth',3);
errorbar(nanmean(cond_means,1), cond_ci,'Color',avgColor,'LineWidth',3);
set(gca,'XTick',1:3,'XTickLabel',conds)
%YTick = get(gca,'YTick');
%set(gca,'YTick',min(YTick):200:max(YTick))
ax = axis;
axis([.5 length(conds)+.5 ax(3) ax(4)])
makeFig4Screen;
