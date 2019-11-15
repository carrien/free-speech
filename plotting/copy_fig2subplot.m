function [HNEWFIG] = copy_fig2subplot(hfig2copy,hnewfig,nrows,ncols,subplotnum)
%COPY_FIG2SUBPLOT  Copy a single-axes figure to a subplot in a new figure.
%   COPY_FIG2SUBPLOT(HFIG2COPY,HNEWFIG)

if nargin < 2 || isempty(hnewfig), hnewfig = figure; end
if nargin < 3 || isempty(nrows), nrows = 1; end
if nargin < 4 || isempty(ncols), ncols = 2; end
if nargin < 5 || isempty(subplotnum), subplotnum = 1; end

% get handle to axis
hax = hfig2copy.Children; % assume only one axis

% set position and copy
temp_ax = subplot(nrows,ncols,subplotnum,'parent',hnewfig);
haxcp = copyobj(hax, hnewfig);
set(haxcp,'Position',get(temp_ax,'position'));
delete(temp_ax);
