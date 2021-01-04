function [hnewfig] = copy_fig2subplot(hfig2copy,hnewfig,nrows,ncols,subplotnums,bCloseOrig)
%COPY_FIG2SUBPLOT  Copy a single-axes figure to a subplot in a new figure.
%   [HNEWFIG] = COPY_FIG2SUBPLOT(HFIG2COPY,HNEWFIG,NROWS,NCOLS,SUBPLOTNUM)

if nargin < 2 || isempty(hnewfig), hnewfig = figure; end
if nargin < 3 || isempty(nrows), nrows = 1; end
if nargin < 4 || isempty(ncols), ncols = length(hfig2copy); end
if nargin < 5 || isempty(subplotnums), subplotnums = num2cell(1:length(hfig2copy)); end
if nargin < 6 || isempty(bCloseOrig), bCloseOrig = 0; end

for ifig = 1:length(hfig2copy)
    % get handle to axis
    if strcmp(get(hfig2copy(ifig), 'type'), 'figure')
        hax = get(hfig2copy(ifig),'Children'); % assume only one axis
    else
        hax = hfig2copy(ifig);
    end
    
    % set position and copy
    temp_ax = subplot(nrows,ncols,subplotnums{ifig},'parent',hnewfig);
    pause(.05);
    haxcp = copyobj(hax, hnewfig);
    pause(.05);
    for nax = 1:length(haxcp)
        if isa(haxcp(nax),'matlab.graphics.axis.Axes')
            set(haxcp(nax),'Position',get(temp_ax,'Position'));
            set(haxcp(nax),'Colormap',get(hax(nax),'Colormap'));
        else % e.g. a legend
            % calculate position relative to parent axes
            %set(haxcp(nax),'Position',get(temp_ax,'Position'))
        end
    end
    delete(temp_ax);
    
    % close original figure
    if bCloseOrig && strcmp(get(hfig2copy(ifig), 'type'), 'figure')
        close(hfig2copy(ifig));
    end
end
