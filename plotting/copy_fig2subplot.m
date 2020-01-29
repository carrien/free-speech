function [hnewfig] = copy_fig2subplot(hfig2copy,hnewfig,nrows,ncols,subplotnums)
%COPY_FIG2SUBPLOT  Copy a single-axes figure to a subplot in a new figure.
%   [HNEWFIG] = COPY_FIG2SUBPLOT(HFIG2COPY,HNEWFIG,NROWS,NCOLS,SUBPLOTNUM)

if nargin < 2 || isempty(hnewfig), hnewfig = figure; end
if nargin < 3 || isempty(nrows), nrows = 1; end
if nargin < 4 || isempty(ncols), ncols = length(hfig2copy); end
if nargin < 5 || isempty(subplotnums), subplotnums = num2cell(1:length(hfig2copy)); end

for ifig = 1:length(hfig2copy)
    % get handle to axis
    hax = get(hfig2copy(ifig),'Children'); % assume only one axis
    
    % set position and copy
    temp_ax = subplot(nrows,ncols,subplotnums{ifig},'parent',hnewfig);
    pause(1);
    haxcp = copyobj(hax, hnewfig);
    pause(1);
    set(haxcp,'Position',get(temp_ax,'position'));
    delete(temp_ax);
end
