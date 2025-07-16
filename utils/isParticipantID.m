function [validIndices, validIDs] = isParticipantID(inputArray)
% Checks if strings are valid format for participant ID, e.g., sp123
%   [validIndices, validIDs] = isParticipantID(inputArray) returns:
%       - validIndices: a vector of indices into inputArray of valid
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
goodPrefixes = {'sp', 'pd', 'ca', 'ap'};

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
validIndices = find(ix == true);

end %EOF
