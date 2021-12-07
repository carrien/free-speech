function [bstSubjDir] = get_bstSubjDir(exptName,sid)
%GET_BSTSUBJDIR  Return path to subject directory in Brainstorm database.
%   GET_BSTSUBJDIR(EXPTNAME,SID)
%       Given an experiment name and subject ID, return the path to the
%       subject's directory in the brainstormDB folder. 
%       ARGUMENTS
%           EXPTNAME - experiment name as specified in brainstormDB. Same
%           as the name of the protocol in brainstorm.
%           SID - subject ID, same as specified in brainstorm protocol.
%       OUTPUT
%           BSTSUBJDIR -  path to the provided subject's data directory in
%           the brainstormDB location.        

if isnumeric(sid)
    sid = sprintf('s%02d',sid); % create string from numeric for sid.
end

dbpath = bst_get('BrainstormDbDir'); % get the brainstorm db path.
bstSubjDir = fullfile(dbpath,exptName,'data',sid); %set up subject dir to return. 

end
