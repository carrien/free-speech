function [figwords] = calc_jasa_words_figures(figSizeArray, cols)

% figSizeArray is an array of figure dimensions: 
% [width1 height1; width2 height2] etc

% cols is a cell array that indicates whether each figure is 'single'
% column or 'double' column. Default is single column.

if nargin < 3 || isemtpy(cols), cols = cell(size(figSizeArray,1),1); cols(:) = {'single'}; end

for f = 1:size(figSizeArray,1)
    tw = figSizeArray(f,1);
    th = figSizeArray(f,2);
    asprat = tw/th;
    if strcmpi(cols{f},'single')
        figwords(f) = (150/asprat) + 20;
    elseif strcmpi(cols{f},'double')
        figwords(f) = (150/asprat) + 40; % guidance actually says 300/0.5 x aspect ratio + 40...not sure how 300/0.5 isn't 150?
    else
        error('must specify single or double column for all figures in cols variable')
    end
end