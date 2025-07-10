function [validIndeces, validIDs] = isParticipantID(inputArray)
% isParticipantID checks if strings match participant ID criteria.
%   [validIndeces, validIDs] = isParticipantID(inputArray) returns:
%       - validIndeces: a vector of indeces into inputArray of valid
%       participant IDs
%       - validIDs: a cell array of the valid participant IDs
%   input cell array or string array:
%       - has a length of 3 or more
%       - starts with 'sp', 'pd', or 'ca'
%   Otherwise, returns 0.

% Ensure input is a cell array of character vectors
if isstring(inputArray)
    inputArray = cellstr(inputArray);
elseif ischar(inputArray)
    inputArray = {inputArray};
end

% Define acceptable prefixes
goodPrefixes = {'sp', 'pd', 'ca'};

% Preallocate result array of boolean values
ix = false(size(inputArray));

% Loop through each element
for i = 1:length(inputArray)
    str = inputArray{i};
    if length(str) >= 3
        prefix = str(1:2);
        if any(strcmp(prefix, goodPrefixes))
            ix(i) = true;
        end
    end
end

% Extract valid IDs
validIDs = inputArray(ix);
validIndeces = find(ix == true);

end %EOF
