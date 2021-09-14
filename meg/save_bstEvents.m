function [eventFiles] = save_bstEvents(dataFiles,outPath)
%SAVE_BSTEVENTS  Exports event markers from a list of Brainstorm raw files.
%   SAVE_BSTEVENTS(DATAFILES, OUTPATH)
%       
%       ARGUMENTS
%           DATAFILES
%           
%           OUTPATH
%
%       OUTPUT
%           EVENTFILES

%Check to see if provided output location exists, make it if it does not.
if ~exist(outPath)
    mkdir(outPath)
end

%Loop over elements of dataFiles
eventFiles = cell(1,length(dataFiles));
for i=1:length(dataFiles)
    
    %load dataFile structure
    [~,filename] = fileparts(dataFiles{i});
    data = load(dataFiles{i});
    
    %Extract events from dataFile structure
    events = data.F.events; %#ok<NASGU>
    eventfilename = sprintf('events_%s.mat',filename(11:end));
    
    %Store event information in eventFiles array
    eventFiles{i} = fullfile(outPath,eventfilename);
   
    %Save event information in event file
    bSave = savecheck(eventFiles{i});
    if bSave
        save(eventFiles{i},'events');
        fprintf('Event file written to %s\n',eventFiles{i});
    end
    
end