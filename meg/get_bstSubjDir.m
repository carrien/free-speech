function [bstSubjDir] = get_bstSubjDir(exptName,sid)
%GET_BSTSUBJDIR  Return path to subject directory in Brainstorm database.
%   GET_BSTSUBJDIR(EXPTNAME,SID)

if isnumeric(sid)
    sid = sprintf('s%02d',sid); % create string from numeric for sid
end

%dbpath = bst_get('BrainstormDbDir');
dbpath = '/projectnb/skiran/brainstorm_db';
bstSubjDir = fullfile(dbpath,exptName,'data',sid);
