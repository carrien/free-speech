function [hfig] = plot_fmtMatrix(dataPath,plotfile,toPlot,errtype,linecolors)
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
if ~exist('tstep','var')
    load(fullfile(dataPath,'dataVals.mat'),'dataVals');
    goodtrials = find(~[dataVals.bExcl]);
    tstep = mean(diff(dataVals(goodtrials(1)).ftrack_taxis));
end
alltime = 0:tstep:1.5;

% TODO: special perc upper and lower bounds
if strncmp(toPlot,'perc',4)
    %    percd1.mean{c} = percdiff1_mean.(conds{c});
    %    percd2.mean{c} = percdiff2_mean.(conds{c});
end

%% plot

% set line colors
if ~exist('linecolors','var') || isempty(linecolors)
    linecolors = get_colorStruct(conds);
elseif ~isstruct(linecolors)
    linecolors = get_colorStruct(conds,linecolors);
end

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
hfig = figure;
axes('Position',axpos);
htracks = zeros(1,length(conds)); % handles to each track
for c = 1:length(conds)
    cnd = conds{c};
    linecolor = linecolors.(cnd);
    errcolor = get_lightcolor(linecolor);
    % plot tracks
    sig = fmtMeans.(toPlot).(cnd);
    htracks(c) = plot(alltime(1:length(sig)), sig', 'LineWidth', 3, 'Color', linecolor); hold on;
    % plot errorbars
    err = get_errorbars(fmtMatrix.(toPlot).(cnd),errtype,size(fmtMatrix.(toPlot).(cnd),2));
    err = err(~isnan(err));
    sig = sig(~isnan(err));
    fill([alltime(1:length(sig)) fliplr(alltime(1:length(sig)))], [sig'+err' fliplr(sig'-err')], errcolor, ...
        'EdgeColor', errcolor, 'FaceAlpha', .5, 'EdgeAlpha', 0);
    if exist('percNaN','var')
        hashalf_s(c) = find(percNaN.(cnd) <= 50, 1, 'last')*tstep; %#ok<AGROW>
        hasquart_s(c) = find(percNaN.(cnd) <= 75, 1, 'last')*tstep; %#ok<AGROW>
    else
        hashalf_s(c) = find(hashalf.(cnd), 1, 'last')*tstep; %#ok<AGROW>
        hasquart_s(c) = find(hasquart.(cnd), 1, 'last')*tstep; %#ok<AGROW>
    end
end
if ~strncmp(toPlot,'raw',3)
    hline(0,'k');  % draw y = 0 line (if not plotting raw formants)
end
vline(mean(hashalf_s),'k','--'); % median survival time
vline(mean(hasquart_s),'k',':'); % 25% survival time
legend(htracks, conds, 'Location','SouthEast'); legend boxoff;
xlabel(xlab, 'FontWeight', 'bold', 'FontSize', 11);
ylabel(ylab, 'FontWeight', 'bold', 'FontSize', 11);
set(gca, 'FontSize', 10); set(gca, 'TickLength', [0.0 0.0]);
title(sprintf('%s %s',slab,toPlot));
makeFig4Screen;
