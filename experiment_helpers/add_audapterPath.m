function [] = add_audapterPath(audapterType)
% Adds to path the appropriate Audapter file 
% types: 1D, 2D, highFs, bugfix versions of 1d and HighFs, Flex 

if ispc
    audapterPath = 'C:\Users\Public\Documents\software\audapter_mex'; 
elseif ismac
    audapterPath = 'C:/Users/Public/Documents/software/audapter_mex'; 
end

addpath(fullfile(audapterPath,audapterType));

end