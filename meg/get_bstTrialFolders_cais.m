function [bstTrialFolders] = get_bstTrialFolders(exptName,sid,cond,language)
%GET_BSTTRIALFOLDERS  Return paths to trial (epoch) folders in Brainstorm database.
%   GET_BSTTRIALFOLDERS(EXPTNAME,SID)

bstSubjDir = get_bstSubjDir(exptName,sid);

if any(strcmp(cond,{'Listen','Speak'})) % if plain speak or listen, return all numbered dirs
    match = sprintf('%s[123]$',cond);
    d = dir(bstSubjDir);
    d = d([d.isdir]);
    dirnames = {d.name};
    conddirs = ~cellfun(@isempty, regexp(dirnames,match));
    conddirnames = {d(conddirs).name};
elseif strcmp(cond,'cvp')
    conddirnames = {sprintf('%sspeak_center',language), sprintf('%sspeak_periph',language), sprintf('%slisten_center',language), sprintf('%slisten_center',language)};
elseif strcmp(cond,'speak_cvp')
    conddirnames = {sprintf('%sspeak_center',language), sprintf('%sspeak_periph',language)};
elseif strcmp(cond,'listen_cvp')
    conddirnames = {sprintf('%slisten_center',language), sprintf('%slisten_center',language)};
end



bstTrialFolders = fullfile(bstSubjDir,conddirnames);