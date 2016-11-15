function [] = plot_fmtMatrix(dataPath,plotfile,toPlot,errtype,linecolors)
%PLOT_FMTMATRIX  Plot formant difference tracks per condition.
%   PLOT_FMTMATRIX(DATAPATH,PLOTFILE,TOPLOT,ERRTYPE,LINECOLORS) plots
%   a formant tracks for each condition in the formant matrix specified in
%   PLOTFILE (e.g. 'fmtMatrix_EtoIEtoAE_noshift.mat'). TOPLOT specifies
%   which type of track to plot (e.g. 'rawf1' or 'diff2'). ERRTYPE
%   determines the type of error bars plotted (95% CI vs. SE vs STD).
%
% cn 11/2014

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(toPlot), toPlot = 'rawf1'; end
if nargin < 4 || isempty(errtype), errtype = 'se'; end

% load plotfile
load(fullfile(dataPath,plotfile));
conds = fieldnames(fmtMatrix.(toPlot));

% get time axis
load(fullfile(dataPath,'dataVals.mat'),'dataVals');
goodtrials = find(~[dataVals.bExcl]);
tstep = mean(diff(dataVals(goodtrials(1)).ftrack_taxis));
alltime = 0:tstep:1.5;

% TODO: special perc upper and lower bounds
if strncmp(toPlot,'perc',4)
    %    percd1.mean{c} = percdiff1_mean.(conds{c});
    %    percd2.mean{c} = percdiff2_mean.(conds{c});
end

%% plot

% set line colors
if nargin < 5 || isempty(linecolors)
    linecolors = get_colors(length(conds));
end
errcolors = linecolors + (1-linecolors)./3;

% set axis labels and position
if bMels
    unit = 'mels';
else
    unit = 'Hz';
end
xlab = 'time (s)';
ylab = sprintf('%s (%s)',toPlot,unit);
slab = dataPath; slab(strfind(slab,filesep)) = ' '; key = 'acousticdata '; ind = strfind(slab,key);
if ind % shorten subj label if possible
    slab = slab(ind(1)+length(key):end);
end
axpos = [0.14 0.14 .8 .8];

% create figure
figure;
axes('Position',axpos);
h = zeros(1,length(conds)); % handles to each track
for c = 1:length(conds)
    cnd = conds{c};
    % plot tracks
    sig = fmtMeans.(toPlot).(cnd);
    h(c) = plot(alltime(1:length(sig)), sig', 'LineWidth', 3, 'Color', linecolors(c,:)); hold on;
    % plot errorbars
    err = get_errorbars(fmtMatrix.(toPlot).(cnd),errtype,size(fmtMatrix.(toPlot).(cnd),2));
    err = err(~isnan(err));
    sig = sig(~isnan(err));
    fill([alltime(1:length(sig)) fliplr(alltime(1:length(sig)))], [sig'+err' fliplr(sig'-err')], errcolors(c,:), ...
        'EdgeColor', errcolors(c,:), 'FaceAlpha', .5, 'EdgeAlpha', 0);
    hasquart_s(c) = find(hasquart.(cnd), 1, 'last')*tstep; %#ok<AGROW>
end
hline(0,'k');
vline(mean(hasquart_s),'k','--');
legend(h, conds, 'Location','SouthEast'); legend boxoff;
xlabel(xlab, 'FontWeight', 'bold', 'FontSize', 11);
ylabel(ylab, 'FontWeight', 'bold', 'FontSize', 11);
set(gca, 'FontSize', 10); set(gca, 'TickLength', [0.0 0.0]);
title(sprintf('%s %s',slab,toPlot));