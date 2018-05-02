function [rundir] = get_meg_rundirs(exptName,snum,megsubdir,nruns)
%GET_MEG_RUNDIRS  Get path to MEG run directories.

if nargin < 3 || isempty(megsubdir), megsubdir = 'meg'; end
if nargin < 4, nruns = 4; end

for i=1:nruns
    rundirname = sprintf('run%02d',i);
    rundir{i} = get_acoustLoadPath(exptName,snum,megsubdir,rundirname);
end

