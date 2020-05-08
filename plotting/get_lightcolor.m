function [lightcolor] = get_lightcolor(color,lightFactor)
%GET_LIGHTCOLOR  Return a lighter version of the input color.

if nargin < 1 || isempty(color), color = [1 0 0]; end
if nargin < 2 || isempty(lightFactor), lightFactor = .3; end

lightcolor = color + lightFactor;
lightcolor(lightcolor > 1) = 1;

% hardcoded light colors
if isequal(color, [.4 .7 .06])  % green (vsaAdapt)
    lightcolor = [.55 .85 .15];
elseif isequal(color,[.1 .6 .9]) % cyan (vsaAdapt)
    lightcolor = [.3 .8 1];
end
