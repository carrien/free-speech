function [colors] = get_colors(nlines)
%GET_COLORS  Get default colors for plotting.

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

if nlines < 5
    colors = lines;
elseif nlines > length(colors)
    colors = varycolor(nlines);
end
