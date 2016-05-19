function [] = plot_fmtMatrix(exptName,snum,plotfile,toPlot,errtype)
%PLOT_FMTMATRIX  Plot formant difference tracks per condition.
%   PLOT_FMTMATRIX(EXPTNAME,SNUM,PLOTFILE,ERRTYPE) plots a formant track
%   for each condition in the fmtMatrix specified in PLOTFILE (e.g.
%   'fmtMatrix_EtoIEtoAE_noshift.mat'). For a non-zero subject number SNUM,
%   plot a single subject. For SNUM == 0, use a multi-subject file located
%   in EXPTNAME's acousticdata dir. ERRTYPE determines the type of error
%   bars plotted (95% CI vs. SE vs STD).
%
% cn 11/2014

if nargin < 4 || isempty(toPlot), toPlot = 'rawf1'; end
if nargin < 5, errtype = 'se'; end

if isempty(snum)
    dataPath = get_exptPath(exptName,'acousticdata');
else
    if strcmp(exptName,'cat'), dataPath = getAcoustSubjPath(exptName,snum,'pert','formant_analysis');
    elseif strcmp(exptName,'vin'), dataPath = getAcoustSubjPath(exptName,snum,'all');
    else dataPath = getAcoustSubjPath(exptName,snum);
    end
end
load(fullfile(dataPath,plotfile),'fmtMatrix','fmtMeans');
conds = fieldnames(fmtMatrix.(toPlot));
if strcmp(exptName,'cat'), tstep = .004; else tstep = .003; end
alltime = 0:tstep:1.5;

% TODO: special perc upper and lower bounds
if strncmp(toPlot,'perc',4)
%    percd1.mean{c} = percdiff1_mean.(conds{c});
%    percd2.mean{c} = percdiff2_mean.(conds{c});
end

%% plot

linecolors = {'r' [0.355 0.355 0.355] 'b' 'g'};
sdcolors = {[1 0.502 0.251] [0.655 0.655 0.655] 'c' 'y'};
xlab = 'time (s)';
figpos = [0.14 0.14 .8 .8];

figure;
axes('Position',figpos);
h = zeros(1,length(conds));

for c = 1:length(conds)
    cnd = conds{c};
    % plot tracks
    sig = fmtMeans.(toPlot).(cnd);
    h(c) = plot(alltime(1:length(sig)), sig', 'LineWidth', 3, 'Color', linecolors{c}); hold on;
    % plot errorbars
    err = get_errorbars(fmtMatrix.(toPlot).(cnd),errtype,size(fmtMatrix.(toPlot).(cnd),2));
    err = err(~isnan(err));
    sig = sig(~isnan(err));
    fill([alltime(1:length(sig)) fliplr(alltime(1:length(sig)))], [sig'+err' fliplr(sig'-err')], sdcolors{c}, ...
        'EdgeColor', sdcolors{c}, 'FaceAlpha', .5, 'EdgeAlpha', 0);
end
legend(h, conds, 'Location','SouthEast'); legend boxoff;
xlabel(xlab, 'FontWeight', 'bold', 'FontSize', 11);
ylabel(toPlot, 'FontWeight', 'bold', 'FontSize', 11);
set(gca, 'FontSize', 10); set(gca, 'TickLength', [0.0 0.0]);
%hline(0);
%axis([alltime(1) alltime(min(stop)) -100 100])
