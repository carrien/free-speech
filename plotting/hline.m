function hl = hline(val,color,linestyle,ax)
% function hl = hline(val,color,linestyle,ax)

% This function draws a horizontal line extending to the axis left and
% right limits at runtime. Note that if the axis left-right limits are
% changed later, the line will retain its original limits.
%
% If you instead want a horizontal line that extends infinitely left and
% right, use the MATLAB built-in function YLINE. Note that YLINE creates a
% LineConstant type object, whereas HLINE creates a Line type object, so
% some object properties may have different names.

if nargin < 4, ax = gca; end

a = axis(ax);
hl = line(a(1:2),val*ones(2,1),'Parent',ax);

if nargin >= 2
  set(hl,'Color',color);
end
if nargin >= 3
  set(hl,'LineStyle',linestyle);
end

end %EOF
