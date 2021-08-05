function [gitpath] = get_gitPath
% INSTRUCTIONS: If you need to change this, copy this file outside of a git
% repo, save locally, and add the copy to the top of your MATLAB path. You
% can then remove all of the code, except for one line which hard-codes to
% the proper filepath.

% gitpath = 'C:\Users\Public\Documents\software'; OLD METHOD
fileloc = which('get_gitPath.m', '-all');

if isempty(fileloc)
    error(['Couldn''t find a file named get_gitPath when searching the MATLAB path. ' ...
        'Ensure free-speech\experiment_helpers\get_gitPath is on your MATLAB path.']);
end

if length(fileloc) > 1
    warning(['You have more than one file called get_gitPath in your MATLAB path. ' ...
        'Using top-listed filepath. Ensure this is the correct one to use.'])
    which get_gitPath.m -all
end

% Go 3 levels up from get_gitPath to reach the folder containing free-speech
path_parts = strsplit(fileloc{1}, filesep);
repo_ix = find(strcmp(path_parts, 'free-speech'));

gitpath = strjoin(path_parts(1:repo_ix - 1), filesep);



end