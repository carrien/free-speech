function [bstRawFiles] = get_bstRawFiles(exptName,sid)
%GET_BSTRAWFILES  Return paths to raw files in Brainstorm database.
%   GET_BSTRAWFILES(EXPTNAME,SID)

bstSubjDir = get_bstSubjDir(exptName,sid);

d = dir(fullfile(bstSubjDir,'@raw*'));
z = d(end); d(end) = []; d = [z; d]; % reorder to put unsuffixed file first
bstRawFolders = fullfile(bstSubjDir,{d.name});

bstRawFiles = cell(1,length(bstRawFolders));
for f=1:length(bstRawFolders)
    rawfile = dir(fullfile(bstRawFolders{f},'data_0raw_*'));
    if ~isempty(rawfile)
        bstRawFiles{f} = fullfile(bstRawFolders{f},rawfile.name);
    end
end