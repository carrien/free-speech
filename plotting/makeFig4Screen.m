function [] = makeFig4Screen(hax,bChildLineWidth)

if nargin < 1 || isempty(hax), hax = gca; end
if nargin < 2 || isempty(bChildLineWidth), bChildLineWidth = 1; end

hax.LineWidth = 1;
hax.XColor = [0 0 0];
hax.YColor = [0 0 0];
hax.FontName = 'Arial';
hax.FontSize = 14;
%set(gcf,'Color','none')
box off;

if bChildLineWidth
    for c = 1:length(hax.Children)
        if isprop(hax.Children(c),'LineWidth') && hax.Children(c).LineWidth < 1
            hax.Children(c).LineWidth = 1;
        end
    end
end