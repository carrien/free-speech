function [hnewfig] = copy_fig2tiledlayout(hfig2copy,hnewfig,nrows,ncols,tilenums,spans,bCloseOrig,plotParams)
%COPY_FIG2TILEDLAYOUT  Copy a single-axes figure to a tiledlayout in a new figure.
%   [HNEWFIG] = COPY_FIG2TILEDLAYOUT(HFIG2COPY,HNEWFIG,NROWS,NCOLS,TILENUMS,SPANS,BCLOSEORIG,PLOTPARAMS)

if nargin < 2 || isempty(hnewfig), hnewfig = figure; end
if nargin < 3 || isempty(nrows), nrows = 1; end
if nargin < 4 || isempty(ncols), ncols = length(hfig2copy); end
if nargin < 5 || isempty(tilenums), tilenums = 1:length(hfig2copy); end
if nargin < 6 || isempty(spans), spans = repmat({[1 1]},1,length(hfig2copy)); end
if nargin < 7 || isempty(bCloseOrig), bCloseOrig = 0; end
if nargin < 8, plotParams = []; end

defaultParams.TileSpacing = 'none';
defaultParams.Padding = 'compact';
plotParams = set_missingFields(plotParams,defaultParams,0);

% create tiledlayout in new figure
tl = tiledlayout(hnewfig,nrows,ncols);
tl.TileSpacing = plotParams.TileSpacing;
tl.Padding = plotParams.Padding;

for ifig = 1:length(hfig2copy)
    % get handle to axis
    if strcmp(get(hfig2copy(ifig), 'type'), 'figure')
        hax = findobj(hfig2copy(ifig),'Type','Axes'); % assume only one axis
    else
        hax = hfig2copy(ifig);
    end
    
    hax.Parent=tl;
    hax.Layout.Tile=tilenums(ifig);
    hax.Layout.TileSpan=spans{ifig};
    
    % close original figure
    if bCloseOrig && strcmp(get(hfig2copy(ifig), 'type'), 'figure')
        close(hfig2copy(ifig));
    end
end
