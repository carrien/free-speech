function [exptInfo] = get_exptInfo(exptName) %#ok<STOUT>
% Get expt universals

dataPath = get_acoustLoadPath(exptName);
load(fullfile(dataPath,'exptInfo.mat'),'exptInfo');