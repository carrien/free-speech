function [] = plot_fmtMatrix_crossSubj(dataPath,plotfile,toPlot,errtype,bflipsig,bsigbar,fx)
%PLOT_FMTMATRIX_CROSSSUBJ  Plot magnitude of compensation across subjects.
%   PLOT_FMTMATRIX_CROSSSUBJ(EXPTNAME,PLOTFILE,ERRTYPE,BFLIPSIG,BSIGBAR)
%   plots formant tracks per condition across multiple subjects.
%
% cn 11/2014

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(toPlot), toPlot = 'diff1'; end
if nargin < 4 || isempty(errtype), errtype = 'se'; end
if nargin < 5 || isempty(bflipsig), bflipsig = 0; end
if nargin < 6 || isempty(bsigbar), bsigbar = 0; end
if nargin < 7 || isempty(fx)
    fx = {'ffx'}; % fx = {'ffx','rfx'}; end
elseif ~iscell(fx)
    fx = {fx};
end

load(fullfile(dataPath,plotfile)) % e.g. fmtTraces_3subj.mat
analyses = fieldnames(ffx);
conds = fieldnames(ffx.(analyses{1}));

%%%%if strcmp(exptName,'cat'), tstep = .004; else tstep = .003; end
tstep = .003;

alltime = 0:tstep:1;
stop = 105*ones(1,length(conds)); % crop axis to here

% calculate mean and errorbars
fprintf('Calculating means and error (%s)...',errtype);
for a = 1:length(analyses)
    anl = analyses{a};
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

% calculate significance at each timepoint (assumes 2 conds)
if bsigbar
    fprintf('Calculating significance...');
    for a = 1:length(analyses)
        anl = analyses{a};
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
    linecolors = get_colors(length(conds));
elseif isstruct(linecolors)
    colors2use = zeros(length(conds),3);
    for c=1:length(conds)
        colors2use(c,:) = linecolors.(conds{c});
    end
end
errcolors = linecolors + (1-linecolors)./3;

facealpha = .5;
xlab = 'time (s)';
% account for short mean traces by decreasing stop point
for c=1:length(conds) 
    if length(rfx_mean.diff2d.(conds{c})) < stop(c)
        stop(c) = length(rfx_mean.diff2d.(conds{c}));
    end    
end

% plot
if ischar(toPlot), toPlot = {toPlot}; end
titles = toPlot;
ylabs = toPlot;
for f=1:length(fx)
    for fn=1:length(toPlot)
        figure; %axes('Visible','off');
        % plot only means (for legend)
        for c = 1:length(conds)
            sig = data_mean.(fx{f}).(toPlot{fn}).(conds{c})(1:stop(c));
            if bflipsig && c == 1, sig = -sig; end
            plot(alltime(1:length(sig)), sig', 'LineWidth', 3, 'Color', linecolors(c,:)); hold on;
        end
        legend(conds,'Location','NorthWest'); legend boxoff;
        % plot error
        for c = 1:length(conds)
            sig = data_mean.(fx{f}).(toPlot{fn}).(conds{c})(1:stop(c));
            err = data_err.(fx{f}).(toPlot{fn}).(conds{c})(1:stop(c));
            t = alltime(~isnan(err));
            sig = sig(~isnan(err));
            err = err(~isnan(err));
            if bflipsig && c == 1, sig = -sig; end
            plot_filled_err(t,sig',err',errcolors(c,:),facealpha);
        end
        hline(0,'k');

%        plot([0 alltime(length(sig))],[0 0],'k');

%         title(sprintf('%s (%s)',titles{fn},fx{f}), 'FontWeight', 'bold', 'FontSize', 11);
%         xlabel(xlab, 'FontSize', 14);
%         ylabel(ylabs{fn}, 'FontSize', 14);
%         set(gca, 'FontSize', 12);
%         set(gca,'XTick',(0:.1:alltime(stop(c)))); set(gca, 'TickLength', [0.0 0.0]);
        title(sprintf('%s (%s)',titles{fn},fx{f}), 'FontWeight', 'bold');
        xlabel(xlab);
        ylabel(ylabs{fn});

        ax = axis;
        if bflipsig, ax(3) = -50; ax(4) = 50; end
        axis([alltime(1) alltime(stop(c)) ax(3) ax(4)])
        
        if bsigbar
            [h_fdr,p_fdr] = fdr(p.(fx{f}).(toPlot{fn}),0.05);
            h_fdr(h_fdr==0) = NaN;

            [h_fdr10,p_fdr10] = fdr(p.(fx{f}).(toPlot{fn}),0.10);
            h_fdr10(h_fdr10==0) = NaN;

            h.(fx{f}).(toPlot{fn})(h.(fx{f}).(toPlot{fn})==0) = NaN;
            h1.(fx{f}).(toPlot{fn})(h1.(fx{f}).(toPlot{fn})==0) = NaN;
            h2.(fx{f}).(toPlot{fn})(h2.(fx{f}).(toPlot{fn})==0) = NaN;
            
            plot(t,h.(fx{f}).(toPlot{fn})*(yax(2)-2),'g')
            plot(t,h1.(fx{f}).(toPlot{fn})*(yax(2)-1.5),'Color',linecolors(1,:))
            plot(t,h2.(fx{f}).(toPlot{fn})*(yax(2)-1),'Color',linecolors(2,:))
            
            plot(t,h_fdr*(yax(2)-2.2),'m')
            plot(t,h_fdr10*(yax(2)-2.4),'c')
        end
    end
end