function [] = makeFig4Screen(hax,p,bChildLineWidth)

if nargin < 1 || isempty(hax), hax = gca; end
if nargin < 2 || isempty(p), p = struct; end
if nargin < 3 || isempty(bChildLineWidth), bChildLineWidth = 1; end

% defaults
hax.LineWidth = 1;
hax.XColor = [0 0 0];
hax.YColor = [0 0 0];
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

if bChildLineWidth
    for c = 1:length(hax.Children)
        if isprop(hax.Children(c),'LineWidth') && hax.Children(c).LineWidth < 1
            hax.Children(c).LineWidth = 1;
        end
    end
end