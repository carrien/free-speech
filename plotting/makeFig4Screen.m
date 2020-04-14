function [hax] = makeFig4Screen(hax,p,minChildLineWidth)

if nargin < 1 || isempty(hax), hax = gca; end
if nargin < 2 || isempty(p), p = struct; end
if nargin < 3 || isempty(minChildLineWidth), minChildLineWidth = 1; end

% if input is figure handle, run recursively on child axes
if isa(hax,'matlab.ui.Figure')
    children = get(hax,'Children');
    for c = 1:length(children)
        if isa(children(c),'matlab.graphics.axis.Axes')
            makeFig4Screen(children(c));
        end
    end
    return;
end

% defaults
hax.LineWidth = 1;
if isequal(hax.XColor,[.15 .15 .15]) % default
    hax.XColor = [0 0 0];
end
if isequal(hax.YColor,[.15 .15 .15])
    hax.YColor = [0 0 0];
end
hax.FontName = 'Helvetica';
hax.FontSize = 14;
box off;
%set(gcf,'Color','none')

% user-defined params
fields = fieldnames(p);
for fn = 1:length(fields)
    fieldname = fields{fn};
    hax.(fieldname) = p.(fieldname);
end

if minChildLineWidth
    for c = 1:length(hax.Children)
        if isprop(hax.Children(c),'LineWidth') && hax.Children(c).LineWidth < minChildLineWidth
            hax.Children(c).LineWidth = minChildLineWidth;
        end
    end
end