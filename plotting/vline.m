function hl = vline(val,color,linestyle,ax)
% function hl = vline(val,color,linestyle,ax)

% This function draws a vertical line extending to the axis top and
% bottom limits at runtime. Note that if the axis top-bottom limits are
% changed later, the line will retain its original limits.
%
% If you instead want a vertical line that extends infinitely up and
% down, use the MATLAB built-in function XLINE. Note that XLINE creates a
% LineConstant type object, whereas VLINE creates a Line type object, so
% some object properties may have different names.

if nargin < 4, ax = gca; end

a = axis(ax);
hl = line(val*ones(2,1),a(3:4),'Parent',ax);
set(hl,'LineWidth',1);
if nargin >= 2 && ~isempty(color)
  set(hl,'Color',color);
end
if nargin >= 3 && ~isempty(linestyle)
  set(hl,'LineStyle',linestyle);
end

end %EOF
