function [ ] = save_bstEvents(dataFiles,outPath)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

for i=1:length(dataFiles)
    [~,filename] = fileparts(dataFiles{i});
    data = load(dataFiles{i});
    events = data.F.events;
    eventfilename = sprintf('events_%s',filename);
    save(fullfile(outPath,eventfilename),'events');
end