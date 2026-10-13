function [unique_event_names] = rename_dupUserEvents(original_event_names)
% Function to rename user events (as a cell array) if there are two with the same label. E.g. in "bobby" you might have {'B'
% 'AA' 'B' 'IY'}. This script will turn it into {'B1' 'AA' 'B2' 'IY'}. This is called by scripts that prepare kinematic data,
% since all landmarks need to be unique. 
% 
% Originated in get_uev_from_tg_mpraat RPK in 2026, pulled out as unique function 2026-10-03
% 

dbstop if error

unique_event_names = original_event_names; % initiate 
definedUevNames = original_event_names(~cellfun(@isempty, original_event_names)); % this gets rid of the blank events at the beginning/end
uniqueUevNames = unique(definedUevNames); % this gets the unique items   

if length(uniqueUevNames) ~= length(original_event_names)
    % If there are strings that appear more than once
    % Loop through all the unique UEV names
    for i = 1:length(uniqueUevNames)
        uniqueUev = uniqueUevNames{i}; 
        dupUevIx = sort(find(strcmp(original_event_names, uniqueUev))); % check if there are multiple of them 

        % If there are duplicates of that name
        if length(dupUevIx) > 1 
            % Loop over those indices
            for d = 1:length(dupUevIx)
                dIx = dupUevIx(d); 
                unique_event_names{dIx} = sprintf('%s%d', original_event_names{dIx}, d); % Change them to, e.g., B1 B2 B3
            end
        end
    end
end


