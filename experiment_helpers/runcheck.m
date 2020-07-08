function [bRun] = runcheck(exptname)
%RUNCHECK check if you are sure you want to run an experiement
%   check if you are sure you want to run an experiemnt, used when multiple
%   version or types of experiemnts exist with similar names

if nargin < 1 || isempty(exptname), exptname = 'unknown'; end

if exptname == 'vsaAdapt'
    otherexpt = 'vsaAdapt2';
% else exptname == 'uhdapter'
%     otherexpt = 'uhdapter_down';
else otherexpt = 'unknown'
end

messg = sprintf('You are running %s.  Did you mean to run %s , not %s?',exptname,exptname,otherexpt);
button = questdlg(messg,'Run Check','Yes, run vsaAdapt (1)','No, do not run vsaAdapt (1)','No, do not run vsaAdapt (1)');

switch button
    case 'Yes, run vsaAdapt (1)'
        bRun = 1;
    case 'No, do not run vsaAdapt (1)'
        bRun = 0;
end


end

