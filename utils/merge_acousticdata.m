function [data] = merge_acousticdata(dataPaths,savePath)
%MERGE_ACOUSTICDATA  Merges multiple acoustic data files.
%   MERGE_ACOUSTICDATA(DATAPATHS,SAVEPATH) loops through the directories in
%   DATAPATHS and generates a data.mat file combining the trials in all of
%   them, saved in SAVEPATH.

if nargin < 2, savePath = pwd; end

for i=1:length(dataPaths)
    datapart = load(fullfile(dataPaths{i},'data'));
    datapart = datapart.data;
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
