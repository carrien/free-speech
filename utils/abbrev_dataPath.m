function [shortDataPath] = abbrev_dataPath(dataPath)
%ABBREV_DATAPATH Return abbreviated form of dataPath.
%   ABBREV_DATAPATH(DATAPATH)

basePath = get_exptLoadPath;

if strncmp(dataPath,basePath,length(basePath))
    shortDataPath = dataPath(length(basePath)+1:end);
else
    shortDataPath = dataPath;
end
