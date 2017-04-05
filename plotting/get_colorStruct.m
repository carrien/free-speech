function [colorStruct] = get_colorStruct(conds,colors)
%GET_COLOR_STRUCT  Return struct with one color per condition.

if nargin < 2 || isempty(colors), colors = get_colors(length(conds)); end

for c=1:length(conds)
    cnd = conds{c};
    colorStruct.(cnd) = colors(c,:);
end
