function [] = remove_audapterPath(audapterType)
% Removes from path the appropriate Audapter file 
% types: 1D, 2D, highFs, and statusBugfix versions (added 2/21/2020)
% Nargin = 0 will remove all audapter types from the path

audapterBasePath = fullfile('C:','Users','Public','Documents','software','audapter_mex');  

if nargin < 1 || isempty(audapterType)
    warning('off');
    rmpath(fullfile(audapterBasePath, '1D')); 
    rmpath(fullfile(audapterBasePath, '2D')); 
    rmpath(fullfile(audapterBasePath, 'highFs')); 
    rmpath(fullfile(audapterBasePath, '1DStatusBugfix')); 
    rmpath(fullfile(audapterBasePath, 'highFsStatusBugfix')); 
    warning('on'); % is possible that some won't exist, I don't really care to be informed
else
    rmpath(fullfile(audapterBasePath,audapterType));
end

end