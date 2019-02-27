function [subs] = get_subject_list(dataPath)

% returns list of subjects in a directory, eg acousticdata

if nargin < 1 || isempty(dataPath), dataPath = cd; end

% LIA = ISMEMBER(A,B) for arrays A and B returns an array of the same
%   size as A containing true where the elements of A are in B and false
%   otherwise.


subs = dir(dataPath);
badnames = {'.','..'}
folds2rm = ismember(subs,badnames)
subs(folds2rm) = [];