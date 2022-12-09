function [dataPaths] = get_dataPaths_modelExpt
% Get data paths for participants who completed modelExpt

svec = [100 101 102 103 200 201 202 203]; % made-up spIDs for participants who completed modelExpt
dataPaths = get_acoustLoadPaths('modelExpt',svec);

