function [lightcolor] = get_lightcolor(color,lightFactor)
%GET_LIGHTCOLOR  Return a lighter version of the input color.

if nargin < 1 || isempty(color), color = [1 0 0]; end
if nargin < 2 || isempty(lightFactor), lightFactor = 3; end

lightcolor = color + (1-color)./lightFactor;

end

