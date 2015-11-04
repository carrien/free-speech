function [data] = gen_acousticdata_fusp_merge(dataPath,nblocks,savePath)
%GEN_ACOUSTICDATA_FUSP_MERGE  Converts and merges two fusp runs.
%   GEN_ACOUSTICDATA_FUSP_MERGE calls GEN_ACOUSTICDATA_FUSP on each run and
%   merges the output to a single data file.  DATAPATH is the a cell array
%   of the dataset directories (e.g., {speak1 speak2}); NBLOCKS is a vector
%   array of the number of blocks (e.g. block0-block2 --> n = [3 3]).

if nargin < 2 || isempty(nblocks)
    nblocks = cell(1,length(dataPath));
end
if nargin < 3, savePath = pwd; end

for i=1:length(dataPath)
    datapart = gen_acousticdata_fusp(dataPath{i},nblocks{i});
    if ~exist('data','var')
        data = datapart;
    else
        data(end+1:end+length(datapart)) = datapart;
    end
end

if ~exist(savePath,'dir')
    mkdir(savePath)
end
savefile = fullfile(savePath,'data.mat');
bSave = savecheck(savefile);
if bSave
    save(savefile, 'data');
end