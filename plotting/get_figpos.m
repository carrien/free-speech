function [figpos] = get_figpos(screentype)
%GET_FIGPOS  Shortcut to desired full-window figure position on various machines.
%   e.g. get_figpos('carbo')

if nargin < 1, screentype = 'carbo'; end

switch screentype
    case 'carbo'
        figpos = [10 44 2542 1302];
    case 'lab_old'
        figpos = [1290 185 1902 988];
    case 'lab'
        figpos = [2588 385 1860 948];
    otherwise
        figpos = [10 39 1262 705];
end