function [eventFiles] = save_bstEvents(dataFiles,outPath,bSave)
%SAVE_BSTEVENTS  Exports event markers from a list of Brainstorm raw files.
%   SAVE_BSTEVENTS(DATAFILES, OUTPATH)
%
%       ARGUMENTS
%           DATAFILES
%
%           OUTPATH
%
%           BSAVECHECK
%
%       OUTPUT
%           EVENTFILES

if nargin < 1 || isempty(dataFiles)
    error('Please provide a valid dataFile or set of dataFiles')
end
if nargin < 2 || isempty(outPath)
    warning('No outPath provided, setting to current matlab working directory')
    outpath = cd;
end

%Check to see if provided output location exists, make it if it does not.
if ~exist(outPath,'dir')
    mkdir(outPath)
end

%Loop over elements of dataFiles
eventFiles = cell(1,length(dataFiles));
for i=1:length(dataFiles)
    
    %load dataFile structure
    [~,filename] = fileparts(dataFiles{i});
    data = load(dataFiles{i});
    
    %Extract events from dataFile structure
    events = data.F.events;
    eventfilename = sprintf('events_%s.mat',filename(11:end));
    
    %Store event information in eventFiles array
    eventFiles{i} = fullfile(outPath,eventfilename);
    
    %Save event information in event file
    if nargin < 3 || bSave == 1 %Default is to save if they do not provide bSave.
        bSave = savecheck(eventFiles{i}); %Give user a chance to handle overwrite.
        if bSave
            save(eventFiles{i},'events');
            fprintf('Event file written to %s\n',eventFiles{i});
        end
    end
end
    
end