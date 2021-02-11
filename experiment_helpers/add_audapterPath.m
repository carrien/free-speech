function [] = add_audapterPath(audapterType)
% Adds to path the appropriate Audapter file 
% types: 1D, 2D, highFs, bugfix versions of 1d and HighFs, Flex 

warning(sprintf(['The function add_audapterPath is deprecated and will be deleted soon. You should take these steps: \n'...
    '1. Make sure that "flexdapter" is present on this machine; \n'...
    '2. In the script that is calling this function, be sure that these audapter flags are set properly for using flexdapter: \n\n'...
    'downFact (for sampling rate/filter choices); \npert2D (for 1D vs. 2D audapter)\n\n'...
    '3. Update your script accordingly. Be sure to test before running on a participant.']))

if ispc
    audapterPath = 'C:\Users\Public\Documents\software\audapter_mex'; 
elseif ismac
    audapterPath = 'C:/Users/Public/Documents/software/audapter_mex'; 
end

addpath(fullfile(audapterPath,audapterType));

end