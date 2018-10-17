function [bstTrialFolders] = get_bstTrialFolders(exptName,sid,cond)
%GET_BSTTRIALFOLDERS  Return paths to trial (epoch) folders in Brainstorm database.
%   GET_BSTTRIALFOLDERS(EXPTNAME,SID)

bstSubjDir = get_bstSubjDir(exptName,sid);

if any(strcmp(cond,{'listen','speak'})) % if plain speak or listen, return all numbered dirs
    match = sprintf('%s[123]$',cond);
    d = dir(bstSubjDir);
    d = d([d.isdir]);
    dirnames = {d.name};
    conddirs = ~cellfun(@isempty, regexp(dirnames,match));
    conddirnames = {d(conddirs).name};
elseif strcmp(cond,'cvp')
    conddirnames = {'speak_center', 'speak_periph', 'listen_center', 'listen_periph'};
elseif strcmp(cond,'speak_cvp')
    conddirnames = {'speak_center', 'speak_periph'};
elseif strcmp(cond,'listen_cvp')
    conddirnames = {'listen_center', 'listen_periph'};
end

bstTrialFolders = fullfile(bstSubjDir,conddirnames);