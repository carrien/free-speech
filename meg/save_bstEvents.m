function [eventFiles] = save_bstEvents(dataFiles,outPath)
%SAVE_BSTEVENTS  Exports event markers from a list of Brainstorm raw files.

eventFiles = cell(1,length(dataFiles));
for i=1:length(dataFiles)
    [~,filename] = fileparts(dataFiles{i});
    data = load(dataFiles{i});
    events = data.F.events; %#ok<NASGU>
    eventfilename = sprintf('events_%s',filename(11:end));
    eventFiles{i} = fullfile(outPath,eventfilename);
    save(eventFiles{i},'events');
    fprintf('Event file written to %s\n',eventFiles{i});
end