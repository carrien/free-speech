function [darkcolor] = get_darkcolor(color,darkFactor)
%GET_DARKCOLOR  Return a darker version of the input color.

if nargin < 1 || isempty(color), color = [1 0 0]; end
if nargin < 2 || isempty(darkFactor), darkFactor = 3; end

darkcolor = color - color./darkFactor;

end

