function [ ] = copy_fig2subplot(hfig2copy,hnewfig,nrows,ncols,subplotnum)
%COPY_FIG2SUBPLOT  Copy a single-axes figure to a subplot in a new figure.
%   COPY_FIG2SUBPLOT(HFIG

% get handle to axis
hax = hfig2copy.Children; % assume only one axis

% set position and copy
temp_ax = subplot(nrows,ncols,subplotnum,'parent',hnewfig);
haxcp = copyobj(hax, hnewfig);
set(haxcp,'Position',get(temp_ax,'position'));
delete(temp_ax);
