function [repoPath] = get_gitPath(reponame)
% Returns the filepath to the head folder of the input arg's repository.

if nargin < 1, reponame = 'free-speech'; end

% find path to repo via one of its functions
switch reponame
    case 'free-speech'
        mfilename = 'get_gitPath.m'; % representative function from free-speech
    case 'current-studies'
        mfilename = 'forcedAlignment.m'; % representative function from current-studies
    otherwise
        error('Unknown git repo "%s". Expected "free-speech" or "current-studies".',reponame)
end

fileloc = which(mfilename, '-all');

if isempty(fileloc)
    error('Couldn''t find a file named %s. Ensure the %s repo is on your MATLAB path.',mfilename,reponame);
end

if length(fileloc) > 1
    warning(['You have more than one file called %s in your MATLAB path. ' ...
        'Using top-listed filepath. Ensure this is the correct one to use.'],mfilename)
    which(mfilename, '-all')
end

path_parts = strsplit(fileloc{1}, filesep);
repo_ix = find(strcmp(path_parts, reponame));

repoPath = strjoin(path_parts(1:repo_ix), filesep);

end