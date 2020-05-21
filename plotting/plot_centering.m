function [h] = plot_centering(dataPaths,condtype,conds2plot,plotinds,p)
%PLOT_CENTERING  Plot vowel centering in center and peripheral trials.
%   PLOT_CENTERING reads formants from a subject's fdata file and plots
%   them with respect to the median at both the beginning (first50ms) and
%   middle (mid50p) of each trial.
%                       DATAPATHS: Paths to folders containing
%                       fdata_(condtype).mat from which data should be
%                       plotted
%                       CONDTYPE: condition type to plot e.g. word, vowel
%                       CONDS2PLOT: cell array of desired conditions in fdata
%                       structure e.g. if conds are [aa iy uu] then {'aa'
%                       'uu'}
%                       only plots aa and uu.
%                       PLOTINDS: plotting type - 1 for normalized init->mid,
%                                                 2 for non-normalized,
%                                                 3 for subjects overlaid(normalized)
%                       NTILE: Number of quantiles for determining center
%                       and periphery boundaries
%                       P: plotting parameters structure


%CN 8/2013, Updated NC 4/2020

%% Set missing arguments to defaults
if nargin < 5, p = []; end
pTemplate.xpos = 100;
pTemplate.ypos = 50;
pTemplate.width = 750;
pTemplate.height = 500;
pTemplate.pphColor = [.8 0 0];
pTemplate.cenColor = [0 .8 0];
pTemplate.LineStyle = '--';
pTemplate.Curvature = [1,1];
pTemplate.units = 'mels';
pTemplate.ntile = 5;
pTemplate.bNorm = 1;
p = set_missingFields(p,pTemplate);

if nargin < 1 || isempty(dataPaths), dataPaths = cd; end
if ischar(dataPaths), dataPaths = {dataPaths}; end
if nargin < 2 || isempty(condtype), condtype = 'vowel'; end
if nargin < 3 || isempty(conds2plot)
    %Loads the first dataPath and defaults to all of the words/vowels it
    %finds
    load(fullfile(dataPaths{1},sprintf('fdata_%s.mat',condtype)));
    conds2plot = fieldnames(fmtdata.(p.units));
end
if nargin < 4 || isempty(plotinds), plotinds = 1; end


%% Determine if multiple subject overlay is needed,
%set up graphics objects structure to be returned

if any(plotinds == 2)
    for c = 1:length(conds2plot)
        multi(c) = figure;
    end
    meandist_init_all{length(conds2plot)} = [];
    meandist_mid_all{length(conds2plot)} = [];
end

h = gobjects(1,length(plotinds)); %Structure to be returned by plot_centering,
%contains one figure from each plotting type provided.

%% subject loop
numFigs = 0;
for s=1:length(dataPaths)
    p.condtype = condtype;
    %Load subject's fdata file
    load(fullfile(dataPaths{s},sprintf('fdata_%s.mat',condtype)));
    
    for c = 1:length(conds2plot)
        cond = conds2plot{c};
        data2plot.(p.units).(cond) = fmtdata.(p.units).(cond);
    end
    
    %% init to mid, normalized
    if any(plotinds == 1)
        numFigs = numFigs + 1;
        h(numFigs) = plot_init2mid(data2plot,p);
    end
    
    %% init to mid, normalized, all subj overlaid
    if any(plotinds == 2)
        [multi,meandist_init_all, meandist_mid_all] = ...
            plot_init2mid_multi(data2plot,p,multi,...
            meandist_init_all,meandist_mid_all);
    end
    
end %End subject loop

if any(plotinds == 2)
    numFigs = numFigs + 1;
    maxax = 200;
    tick = -maxax:maxax/2:maxax;
    
    %% overlay init to mid norm summary (circles) for all subjects
    for c = 1:length(conds2plot)
        cnd = conds2plot{c};
        di = nanmean(meandist_init_all{c});
        dm = nanmean(meandist_mid_all{c});
        
        figure(multi(c));
        hold on;
        plot(0,0,'ko')
        rectangle('Position',[-di,-di,di*2,di*2],'Curvature',[1,1],'LineStyle','--','LineWidth',2)
        rectangle('Position',[-dm,-dm,dm*2,dm*2],'Curvature',[1,1],'LineWidth',2)
        xlabel('norm F1 (mels)')
        ylabel('norm F2 (mels)')
        box off
        axis([-maxax maxax -maxax maxax]);
        axis square
        set(gca,'XTick',tick);
        set(gca,'YTick',tick);
        makeFig4Screen;
        
        set(gcf,'Name',sprintf('All-subject overlay, %s %s',...
            condtype,cnd))
        
    end
    h(numFigs) = gcf;
end

end %End function
