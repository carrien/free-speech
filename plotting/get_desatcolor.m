function [desatcolor] = get_desatcolor(color)
%GET_DESATCOLOR  Return a desaturated version of the input color.

if nargin < 1 || isempty(color), color = [1 0 0]; end

gray = repmat(mean(color),1,3);
desatcolor = (color + gray) ./2;

end
