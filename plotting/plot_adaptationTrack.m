function [] = plot_adaptationTrack(exptName,svec,subdirname,avgtype,avgval,binsize,toPlot,plotcolor)
%PLOT_ADAPTATIONTRACK  Plot timecourse of acoustic adaptation.

if nargin < 3, subdirname = []; end
if nargin < 4 || isempty(avgtype), avgtype = 'mid'; end
if nargin < 5 || isempty(avgval), avgval = 50; end
if nargin < 6 || isempty(binsize), binsize = 10; end
if nargin < 7 || isempty(toPlot), toPlot = {'f1' 'f2'}; end
if nargin < 8 || isempty(plotcolor)
    switch avgtype
    case 'mid'
        plotcolor = 'k';
    case 'first'
        plotcolor = 'r';
    case 'next'
        plotcolor = 'g';
    case 'then'
        plotcolor = 'b';
    end
end

% get expt phase info
exptInfo = get_exptInfo(exptName);
vlines(1) = exptInfo.nbasetrials;
vlines(2) = vlines(1) + exptInfo.nramptrials;
vlines(3) = vlines(2) + exptInfo.nholdtrials;
vlines(4) = exptInfo.ntrials - exptInfo.npostbasetrials;

% get subject data
for s=1:length(svec)
    snum = svec(s);
    [~,~,normavg(s)] = get_adaptationTrack(exptName,snum,subdirname,avgtype,avgval,binsize,toPlot); %#ok<AGROW>
end

toBin = fieldnames(normavg); % different bin sizes
for b = 1:length(toBin)
    catOverBins = cat(1,normavg.(toBin{b}));
    for i = 1:length(toPlot)
        allSubj.(toBin{b}).(toPlot{i}) = cat(1,catOverBins.(toPlot{i}));
        allSubjNorm.(toBin{b}).(toPlot{i}) = nanmean(allSubj.(toBin{b}).(toPlot{i}),1);
    end
end

    %% plot
for i=1:length(toPlot)
    % all trials
    figname = toPlot{i};
    figure('Name',sprintf('%s all',figname))
    plot(allSubjNorm.allTrials.(figname),'.','Color',plotcolor)
    % draw lines to separate experiment phases
    for v=1:length(vlines)
        vline(vlines(v));
    end
    hline(0);
    axis tight
    title(figname)
    
    % bins
    if binsize ~= 1
        binfigname = (sprintf('%s binned',figname));
        figure('Name',binfigname)
        plot(allSubjNorm.bins.(figname),'o','Color',plotcolor)
        % draw lines to separate experiment phases
        for v=1:length(vlines)
            vline(vlines(v)/binsize);
        end
        hline(0);
        axis tight
        title(binfigname)
    end
end