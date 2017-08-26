function [events] = merge_events(eventFiles)
%MERGE_EVENTS  Merge multiple Brainstorm event files.
%   MERGE_EVENTS(EVENTFILES) loads data from the list of filepaths in
%   EVENTFILES and returns a single structure with data from all files.

% reorder filepaths to account for zero-indexing
eventFiles = sort_files(eventFiles);

% load initial events file
load(eventFiles{1},'events');
eventnames = {events.label};
fields2rm = {'color','epochs','reactTimes','select'};
events = rmfield(events,fields2rm);
for e=1:length(events)
    events(e).fileind = ones(1,length(events(e).times));
    events(e).eventind = e*ones(1,length(events(e).times));
end

% append events from remaining files
for f=2:length(eventFiles)
    events2add = load(eventFiles{f},'events'); events2add = events2add.events;
    for e=1:length(events2add)
        e_ind = find(strcmp(eventnames,events2add(e).label)); % index in original event struct
        if e_ind
            if ~strcmp(events(e_ind).label,events2add(e).label)
                error('Event names don''t match.')
            end
            events(e_ind).samples = [events(e_ind).samples events2add(e).samples];
            events(e_ind).times = [events(e_ind).times events2add(e).times];
            events(e_ind).fileind = [events(e_ind).fileind f*ones(1,length(events2add(e).times))];
            events(e_ind).eventind = [events(e_ind).eventind e_ind*ones(1,length(events2add(e).times))];
        end
    end
end

for e=1:length(events)
    fprintf('%s: found %d events.\n',events(e).label,length(events(e).samples));
end
