function cbPermutation = set_cbPermutation(exptName, setRow, permPath, population, bSubtract)
% Increments the count column of a given row by one. Should be called after get_cbPermutation
% It is possible to make this more flexible (see, for example, set_cbPermutation_timeAdapt) but for a standard
% call in experiments there should be no reason to increase the count by more or less than one. 
% 
% exptName: e.g. timeAdapt, vsaAdapt
% 
% setRow: the index of the row you want to change. (This will be the output number from get_cbPermutation)
% 
% permPath: should be the same as your experiment path (top level) 
% population: e.g. clinical, control. Use this if you have multiple populations and you're planning to counterbalance within
% population rather than across the whole experiment
% 

if nargin < 3 || isempty(permPath), permPath = cd; end
if nargin < 4 || isempty(population)
    populationStr = '';
else
    populationStr = strcat('_', population); %prepend underscore
end
if nargin < 5, bSubtract = 0; end

permFile = strcat('cbPermutation_', exptName, populationStr, '.mat');

if ~exist(fullfile(permPath, permFile),'file')
    error('Did not find a file called %s in directory %s\n', permFile, permPath); 
end

perms = load(fullfile(permPath, permFile)); 
varField = fieldnames(perms); 
cbPermutation = perms.(char(varField));

[~,countCol] = size(cbPermutation); % Find the column that counts the number of uses
currentCount = cbPermutation{setRow,countCol}; 
if bSubtract == 0
    newCount = currentCount + 1; 
elseif bSubtract == 1
    newCount = currentCount - 1;
end
cbPermutation{setRow,countCol} = newCount; 

save(fullfile(permPath, permFile),'cbPermutation')

end