function [] = plot_fmtMatrix_crossSubj(dataPath,plotfile,toPlotList,errtype,linecolors,bsigbar,fx)
%PLOT_FMTMATRIX_CROSSSUBJ  Plot magnitude of compensation across subjects.
%   PLOT_FMTMATRIX_CROSSSUBJ(DATAPATH,PLOTFILE,TOPLOTLIST,ERRTYPE,BSIGBAR,FX,LINECOLORS)
%   plots formant tracks per condition across multiple subjects.
%
% cn 11/2014

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(toPlotList), toPlotList = {'diff1'}; end
if nargin < 4 || isempty(errtype), errtype = 'se'; end
if nargin < 6 || isempty(bsigbar), bsigbar = 0; end
if nargin < 7 || isempty(fx)
    fx = {'ffx'}; % fx = {'ffx','rfx'}; end
elseif ~iscell(fx)
    fx = {fx};
end

load(fullfile(dataPath,plotfile)) % e.g. fmtTraces_10s.mat
analyses = fieldnames(ffx);

% calculate mean and errorbars
fprintf('Calculating means and error (%s)...',errtype);
for a = 1:length(analyses)
    anl = analyses{a};
    conds = fieldnames(ffx.(anl));
    for c=1:length(conds)
        cnd = conds{c};
        ffx_mean.(anl).(cnd) = nanmean(ffx.(anl).(cnd),2);
        rfx_mean.(anl).(cnd) = nanmean(rfx.(anl).(cnd),2);
        ffx_err.(anl).(cnd) = get_errorbars(ffx.(anl).(cnd),errtype);
        rfx_err.(anl).(cnd) = get_errorbars(rfx.(anl).(cnd),errtype);
    end
end
fprintf('Done.\n');
data_mean = struct('ffx',ffx_mean,'rfx',rfx_mean);
data_err = struct('ffx',ffx_err,'rfx',rfx_err);

%if strcmp(exptName,'cat'), tstep = .004; else tstep = .003; end
if ~exist('tstep','var'), tstep = .003; end
alltime = 0:tstep:1;
conds = fieldnames(ffx.rawf1);
stop_ms = 250;
stop = ms2samps(stop_ms,1/tstep)*ones(1,length(conds)); % crop axis to here

% calculate significance at each timepoint (assumes 2 conds)
if bsigbar
    fprintf('Calculating significance...');
    for a = 1:length(analyses)
        anl = analyses{a};
        conds = fieldnames(ffx.(anl));
        for t = 1:stop(1)
            [h.ffx.(anl)(t),p.ffx.(anl)(t)] = ttest2(ffx.(anl).(conds{1})(t,:),ffx.(anl).(conds{2})(t,:),[],'right');
            [h.rfx.(anl)(t),p.rfx.(anl)(t)] = ttest2(rfx.(anl).(conds{1})(t,:),rfx.(anl).(conds{2})(t,:),[],'right');
            [h1.ffx.(anl)(t),p1.ffx.(anl)(t)] = ttest(ffx.(anl).(conds{1})(t,:),[],[],'right');
            [h1.rfx.(anl)(t),p1.rfx.(anl)(t)] = ttest(rfx.(anl).(conds{1})(t,:),[],[],'right');
            [h2.ffx.(anl)(t),p2.ffx.(anl)(t)] = ttest(ffx.(anl).(conds{2})(t,:),[],[],'right');
            [h2.rfx.(anl)(t),p2.rfx.(anl)(t)] = ttest(rfx.(anl).(conds{2})(t,:),[],[],'right');            
        end
    end
end

%% plot

% plot setup

% set line colors
if ~exist('linecolors','var') || isempty(linecolors)
    linecolors = get_color_struct(conds);
elseif ~isstruct(linecolors) %ismatrix(linecolors)
    linecolors = get_color_struct(conds,linecolors);
end
linestyles = {'-.',':','-','--'};

facealpha = .5;
xlab = 'time (s)';
% account for short mean traces by decreasing stop point
% for c=1:length(conds) 
%     if length(rfx_mean.diff2d.(conds{c})) < stop(c)
%         stop(c) = length(rfx_mean.diff2d.(conds{c}));
%     end    
% end

% plot
if ischar(toPlotList), toPlotList = {toPlotList}; end
titles = toPlotList;
ylabs = toPlotList;
for f=1:length(fx)
    for fn=1:length(toPlotList)
        toPlot = toPlotList{fn};
        figure; %axes('Visible','off');
        % plot only means (for legend)
        conds = fieldnames(ffx.(toPlot));
        for c = 1:length(conds)
            cnd = conds{c};
            linecolor = linecolors.(cnd);
            errcolor = linecolor + (1-linecolor)./3;
            linestyle = linestyles{mod(c,length(linestyles))+1};
            % plot tracks
            sig = data_mean.(fx{f}).(toPlot).(cnd)(1:stop(c));
            h(c) = plot(alltime(1:length(sig)), sig', 'LineWidth',3, 'Color',linecolor, 'LineStyle',linestyle); hold on;
            % plot errorbars
            err = data_err.(fx{f}).(toPlot).(cnd)(1:stop(c));
            %err = get_errorbars(fmtMatrix.(toPlot).(cnd),errtype,size(fmtMatrix.(toPlot).(cnd),2));
            sig = sig(~isnan(err));
            err = err(~isnan(err));
            t = alltime(~isnan(err));

            plot_filled_err(t,sig',err',errcolor,facealpha);

            %fill([alltime(1:length(sig)) fliplr(alltime(1:length(sig)))], [sig'+err' fliplr(sig'-err')], errcolor, 'EdgeColor', errcolor, 'FaceAlpha', .5, 'EdgeAlpha', 0);
            %hashalf_s(c) = find(hashalf.(cnd), 1, 'last')*tstep; %#ok<AGROW>
            %hasquart_s(c) = find(hasquart.(cnd), 1, 'last')*tstep; %#ok<AGROW>            
            
        end
        hline(0,'k');

        %vline(mean(hashalf_s),'k','--');
        legend(h, conds, 'Location','NorthEast'); legend boxoff;
        xlabel(xlab, 'FontSize', 20);
        ylabel(ylabs{fn}, 'FontSize', 20);
        set(gca, 'FontSize', 20);
        set(gca, 'LineWidth', 1);
        %title(sprintf('%s (%s)',titles{fn},fx{f}));
        set(gcf,'Name',sprintf('%s (%s)',titles{fn},fx{f}));
        %title(sprintf('%s %s',slab,toPlot));
        %set(gca,'XTick',(0:.1:alltime(stop(c)))); set(gca, 'TickLength', [0.0 0.0]);

        ax = axis;
        axis([alltime(1) alltime(stop(c)) ax(3) ax(4)])
        box off;
        
        if bsigbar
            [h_fdr,p_fdr] = fdr(p.(fx{f}).(toPlot),0.05);
            h_fdr(h_fdr==0) = NaN;

            [h_fdr10,p_fdr10] = fdr(p.(fx{f}).(toPlot),0.10);
            h_fdr10(h_fdr10==0) = NaN;

            h.(fx{f}).(toPlot)(h.(fx{f}).(toPlot)==0) = NaN;
            h1.(fx{f}).(toPlot)(h1.(fx{f}).(toPlot)==0) = NaN;
            h2.(fx{f}).(toPlot)(h2.(fx{f}).(toPlot)==0) = NaN;
            
            plot(t,h.(fx{f}).(toPlot)*(yax(2)-2),'g')
            plot(t,h1.(fx{f}).(toPlot)*(yax(2)-1.5),'Color',linecolors(1,:))
            plot(t,h2.(fx{f}).(toPlot)*(yax(2)-1),'Color',linecolors(2,:))
            
            plot(t,h_fdr*(yax(2)-2.2),'m')
            plot(t,h_fdr10*(yax(2)-2.4),'c')
        end
    end
end