function [colors] = get_colors(nlines)
%GET_COLORS  Get default colors for plotting.

if nargin < 1, nlines = 6; end

colors = [ ...
    .8 0 0; ...     %r
    1 .6 0; ...     %o
    .95 .85 0; ...  %y
    .55 .85 0; ...  %g
    .2 .6 .8; ...   %b
    .7 .4 .9; ...   %v
    .65 0 0; ...    %R
    .85 .45 0; ...  %O
    .8 .7 0; ...    %Y
    .4 .7 0; ...    %G
    .05 .45 .55; ...%B
    .55 .25 .75; ...%V
    ];

colors = [ ...
    .8 0 0; ...     %r : E
    1 .6 0; ...     %o : I
    .7 .4 .9; ...   %v : ae
    .4 .7 0; ...    %G : eI
    .55 .85 0; ...  %g : i
    .55 .25 .75; ...%V : o
    .2 .6 .8; ...   %b : u
    .95 .85 0; ...  %y
    .65 0 0; ...    %R
    .85 .45 0; ...  %O
    .8 .7 0; ...    %Y
    .05 .45 .55; ...%B
    ];

if nlines < 5
    colors = lines;
elseif nlines > length(colors)
    colors = varycolor(nlines);
end
