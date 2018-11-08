hax = gca;
hax.LineWidth = 1;
hax.XColor = [0 0 0];
hax.YColor = [0 0 0];
hax.FontName = 'Arial';
hax.FontSize = 14;
%set(gcf,'Color','none')
box off;

for c = 1:length(hax.Children)
    if isprop(hax.Children(c),'LineWidth') && hax.Children(c).LineWidth < 1
        hax.Children(c).LineWidth = 1;
    end
end
