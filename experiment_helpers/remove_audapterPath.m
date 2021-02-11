function [] = remove_audapterPath(audapterType)
% Removes from path the appropriate Audapter file 
% types: 1D, 2D, highFs, and statusBugfix versions (added 2/21/2020)
% Nargin = 0 will remove all audapter types from the path

warning(sprintf(['The function remove_audapterPath is deprecated and will be deleted soon. You should take these steps: \n'...
    '1. Make sure that "flexdapter" is present on this machine; \n'...
    '2. In the script that is calling this function, be sure that these audapter flags are set properly for using flexdapter: \n\n'...
    'downFact (for sampling rate/filter choices); \npert2D (for 1D vs. 2D audapter)\n\n'...
    '3. Update your script accordingly. Be sure to test before running on a participant.']))

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