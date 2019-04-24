function [h] = plot2sub(dataPaths,plotfunc,varargin)
%PLOT2SUB  Plot a series of figures as subplots of one figure.
%   H = PLOT2SUB(DATAPATHS,PLOTFUNC,VARARGIN) calls the plotting function
%   PLOTFUNC on each path in DATAPATHS in turn, arraying each resulting
%   plot as a subplot in the new figure H.
%
%   The plotting function PLOTFUNC must:
%   1. take a dataPath as its first input argument
%   2. return a figure handle (with a single child axis) as its first
%      output argument
%
%CN 3/2019

% set up new figure
h = figure('Units','Normalized','Position',[.025 .055 .95 .85]);
npaths = length(dataPaths);
nrows = floor(sqrt(npaths));
ncols = ceil(npaths/nrows);

% plot data
for dP = 1:npaths
    dataPath = dataPaths{dP};
    fprintf('Adding data from %s\n',dataPath);
    
    % create figure to copy
    hfig = plotfunc(dataPath,varargin{:});
    
    % copy child ax
    hax = get(hfig,'Children');    
    c = copyobj(hax,h);
    
    % set as subplot
    bAx = false(size(c));
    for ci = 1:length(c)
        bAx(ci) = isa(c(ci),'matlab.graphics.axis.Axes');
    end
    subplot(nrows,ncols,dP,c(bAx));
    
    % delete copied figure
    delete(hfig)
end
