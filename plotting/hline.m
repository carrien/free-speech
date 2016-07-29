function hl = hline(val,color,linestyle,ax)
% function hl = hline(val,color,linestyle,ax)

if nargin < 4, ax = gca; end

a = axis(ax);
hl = line(a(1:2),val*ones(2,1),'Parent',ax);
if nargin >= 2
  set(hl,'Color',color);
end
if nargin >= 3
  set(hl,'LineStyle',linestyle);
end
