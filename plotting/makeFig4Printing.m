function [hax] = makeFig4Printing(hax,p,minLineWidth)

if nargin < 1 || isempty(hax), hax = gca; end
if nargin < 2 || isempty(p), p = struct; end
if nargin < 3 || isempty(minLineWidth), minLineWidth = 0; end

% if input is figure handle, run recursively on child axes
if isa(hax,'matlab.ui.Figure')
    children = get(hax,'Children');
    for c = 1:length(children)
        if isa(children(c),'matlab.graphics.axis.Axes')
            makeFig4Printing(children(c));
        end
    end
    return;
end

hax = makeFig4Screen(hax,p,minLineWidth);
hax.Color = 'none';
hax.FontSize = 12;
hax.LineWidth = 0.75;