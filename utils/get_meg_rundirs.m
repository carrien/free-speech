function [rundir] = get_meg_rundirs(exptName,snum,nruns)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3, nruns = 4; end

for i=1:nruns
    rundirname = sprintf('run%02d',i);
    rundir{i} = getAcoustSubjPath(exptName,snum,'meg',rundirname);
end

