function [h_fig] = plot_modelExptPaperFigs(figs2plot)
%PLOT_MODELEXPTPAPERFIGS Plot figures for the modelExpt experiment.
%   PLOT_MODELEXPTPAPERFIGS(FIGS2PLOT)
%       Essentially a wrapper for all of the plotting scripts associated with
%       modelExpt. The Matlab built-in dataset 'carsmall.mat' has been used
%       so real data can be plotted.
%
%       Other similar functions in current-studies:
%           plot_postManFigs.m
%           plot_vsaSentencePaperFigs.m
%           plot_voystickPaperFigs.m
%
%       ARGUMENTS:
%           FIGS2PLOT - vector of integers. Identifies which figures
%           below you want to be plotted. 
%
%       OUTPUT:
%           H_FIG - list of figure handles created 
%

if nargin < 1 || isempty(figs2plot), figs2plot = 1:2; end

%% General settings used by multiple figures
defaultParams.Marker = '.';
defaultParams.MarkerSize = 8;
defaultParams.MarkerAlpha = .25;
defaultParams.LineWidth = .6;
defaultParams.LineColor = [.7 .7 .7 .5];
defaultParams.avgMarker = 'o';
defaultParams.avgMarkerSize = 4;
defaultParams.avgLineWidth = 1.25;
defaultParams.jitterFrac = .25;
defaultParams.FontSize = 13;

%% Fig 1: Car weight

[bPlot, ifig] = ismember(1, figs2plot);
if bPlot
    pos = [50 100 1400 870];
    h(ifig) = figure('Position',pos);

    %% set up data to be plotted
    load('carsmall.mat', 'Weight') 

    % make custom changes for this figure
    p.Marker = '+';

    % set up `p` to use defaults otherwise
    p = set_missingFields(p, defaultParams, 0);

    %%
    plot(Weight, 'Marker', p.Marker);
    
    % plot other info
    hline(3000, 'k')
    ylabel('Weight (lbs)')
    title('Car weight')
    makeFig4Screen;
end


%% Fig 2: Car MPG

[bPlot, ifig] = ismember(2, figs2plot);
if bPlot
    pos = [50 100 1400 870];
    h(ifig) = figure('Position',pos);

    %% set up data to be plotted
    load('carsmall.mat', 'MPG') % default dataset native to Matlab

    % make custom changes for this figure
    p.LineColor = [0.7 0 0.7];

    % set up `p` to use defaults otherwise
    p = set_missingFields(p, defaultParams, 0);

    %%
    plot(MPG, 'Color', p.LineColor, 'Marker', p.Marker);
    hold on;
    hline(20, 'k', ':')
    hline(35, 'k', ':')
    
    % plot other info
    ylabel('Miles per gallon')
    title('Car MPGs')
    makeFig4Screen;
end

