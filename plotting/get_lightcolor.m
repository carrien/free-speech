function [lightcolor] = get_lightcolor(color)
%GET_LIGHTCOLOR  Return a lighter version of the input color.

lightcolor = color + (1-color)./3;

end

