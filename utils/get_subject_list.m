function [subs] = get_subject_list(dataPath,subs2exclude,bSPonly)

% returns list of subjects in a directory, eg acousticdata
% subs2exclude is a cell array in that directory.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(subs2exclude), subs2exclude=[]; end
if nargin < 3 || isempty(bSPonly), bSPonly=1; end

% LIA = ISMEMBER(A,B) for arrays A and B returns an array of the same
%   size as A containing true where the elements of A are in B and false
%   otherwise.


subs = dir(dataPath);
subs = subs([subs.isdir]);
badnames = {'.','..'};
subs = {subs.name};
folds2rm = ismember(subs,badnames);
subs(folds2rm) = [];

if isempty(subs2exclude)
    subs2exclude='subs2exclude.mat';
    if exist(subs2exclude)==2
        load(subs2exclude);
    end
end
if iscell(subs2exclude)
    subs2rm = ismember(subs,subs2exclude);
    subs(subs2rm)=[];
end


if bSPonly
    subs = subs(contains(subs,'sp'));
end
    
    