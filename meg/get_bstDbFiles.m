function [bstFiles] = get_bstDbFiles(exptName,sid)
%GET_BSTDBPATHS  Return paths to Brainstorm database.
%   GET_BSTDBPATHS(EXPTNAME,SNUM)

if isnumeric(sid)
    snum = sid;
    sid = sprintf('s%02d',snum);
elseif ischar(sid)
    snum = str2double(regexp(sid,'\d*','Match'));
end

dbpath = '/projectnb/skiran/brainstorm_db';

nfiles = 3;
for i=1:nfiles
    if i==1
        filesuffix = [];
    else
        filesuffix = sprintf('-%d',i-1);
    end
    rawfilename{i} = sprintf('%s%02d%s_tsss_mc',lower(exptName),snum,filesuffix);
    bstFiles{i} = fullfile(dbpath,exptName,'data',sid,sprintf('@raw%s',rawfilename{i}),sprintf('data_0raw_%s.mat',rawfilename{i}));
end
