function [figpos] = get_figpos(screenconfig)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1, screenconfig = 'laptop'; end

switch screenconfig
    case 'laptop'
        figpos = [10 39 1262 705];
    case 'lab'
        figpos = [1290 185 1902 988];
    otherwise
        figpos = [10 39 1262 705];
end