function [exptInfo] = get_exptInfo(exptName) %#ok<STOUT>
% Get expt universals

dataPath = getAcoustSubjPath(exptName);
load(fullfile(dataPath,'exptInfo.mat'),'exptInfo');