function [h,mu,sigma] = plot_distrib_crossSubj(dataPaths,field2plot)
%PLOT_DISTRIB_CROSSUBJ  Plot distributions of a parameter in dataVals.
%   PLOT_DISTRIB_CROSSSUBJ(DATAPATHS,FIELD2PLOT)

if nargin < 2, field2plot = 'dur'; end

switch field2plot
    case 'dur'
        axlab = 'duration (s)';
    otherwise
        axlab = field2plot;
end

nSubj = length(dataPaths);
mu = zeros(1,nSubj);
sigma = zeros(1,nSubj);

h = figure;
tiledlayout(3,1)
hax_hists = nexttile;
hax_pdfs = nexttile;
for dP = 1:nSubj
    dataPath = dataPaths{dP};
    load(fullfile(dataPath,'dataVals.mat'),'dataVals')
    goodTrials = ~[dataVals.bExcl];
    vals = [dataVals(goodTrials).(field2plot)];
    
    axes(hax_hists)
    histogram(vals);
    hold on;
    
    x = min(vals):(max(vals)-min(vals))/100:max(vals);
    mu(dP) = mean(vals);
    sigma(dP) = std(vals);
    axes(hax_pdfs)
    y = normpdf(x,mu(dP),sigma(dP));
    plot(x,y,'LineWidth',1.5)
    hold on;
end
axes(hax_hists)
xlabel(axlab)
makeFig4Screen;

axes(hax_pdfs)
xlabel(axlab)
makeFig4Screen;

nexttile
errorbar(mu,sigma)
xlims = xlim;
xlim([xlims(1)-.5 xlims(2)+.5])
xlabel('subject')
ylabel(axlab)
makeFig4Screen;
