function hl = vline(val,color,linestyle,ax)
% function hl = vline(val,color,linestyle,ax)

if nargin < 4, ax = gca; end

a = axis(ax);
hl = line(val*ones(2,1),a(3:4),'Parent',ax);
if nargin >= 2 && ~isempty(color)
  set(hl,'Color',color);
end
if nargin >= 3 && ~isempty(linestyle)
  set(hl,'LineStyle',linestyle);
end
