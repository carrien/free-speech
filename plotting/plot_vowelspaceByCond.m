function [h] = plot_vowelspaceByCond(dataPath,condtype,conds,avgfn,colors,bPlotCond)
%PLOT_VOWELSPACEBYCOND  Plot 2D vowel formant space by condition.
%   PLOT_VOWELSPACEBYCOND

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(condtype), condtype = 'word'; end
if nargin < 4 || isempty(avgfn), avgfn = 'mid50p'; end
if nargin < 6, bPlotCond = 0; end

% load data
fdataFile = sprintf('fdata_%s.mat',condtype);
load(fullfile(dataPath,fdataFile),'fmtdata');

if nargin < 3 || isempty(conds)
    conds = fieldnames(fmtdata.mels);
end

% set colors
if nargin < 5 || isempty(colors)
    colors = get_colorStruct(conds);
elseif ~isstruct(colors)
    colors = get_colorStruct(conds,colors);
end

% plot vowel space
h = figure;
hdata = cell(1,length(conds));
for c = 1:length(conds)
    % for each condition
    cnd = conds{c};
    f1 = fmtdata.mels.(cnd).(avgfn).rawavg.f1;
    f2 = fmtdata.mels.(cnd).(avgfn).rawavg.f2;
    if bPlotCond
        hdata{c} = text(f1,f2,cnd,'Color',colors.(cnd),'FontSize',14,'HorizontalAlignment','center');
    else
        hdata{c} = plot(f1,f2,'.','Color',colors.(cnd));
    end
    hold on;
    ell = FitEllipse(f1,f2);
    plot(ell(:,1),ell(:,2),'Color',colors.(cnd));
end
if ~bPlotCond
    legend(hdata,conds)
end

xlabel('F1 (mels)')
ylabel('F2 (mels)')
if length(avgfn) > 1
    title(avgfn)
end

makeFig4Screen;
