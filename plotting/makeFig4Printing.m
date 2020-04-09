function [hax] = makeFig4Printing(hax,p,minChildLineWidth)

if nargin < 1 || isempty(hax), hax = gca; end
if nargin < 2 || isempty(p), p = struct; end
if nargin < 3 || isempty(minChildLineWidth), minChildLineWidth = 0.75; end

hax = makeFig4Screen(hax,p,minChildLineWidth);
hax.Color = 'none';
hax.FontSize = 8;
hax.LineWidth = 0.75;