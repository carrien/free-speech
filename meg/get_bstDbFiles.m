function [bstFiles] = get_bstDbFiles(exptName,snum)
%GET_BSTDBPATHS  Return paths to Brainstorm database.
%   GET_BSTDBPATHS(EXPTNAME,SNUM)

dbpath = '/project/skiran/brainstorm_db';

nfiles = 3;
for i=1:nfiles
    if i==1
        filesuffix = [];
    else
        filesuffix = sprintf('-%d',i-1);
    end
    rawfilename{i} = sprintf('%s%02d%s_tsss_mc',lower(exptName),snum,filesuffix);
    bstFiles{i} = fullfile(dbpath,exptName,'data',sprintf('s%02d',snum),sprintf('@raw%s',rawfilename{i}),sprintf('data_0raw_%s.mat',rawfilename{i}));
end
