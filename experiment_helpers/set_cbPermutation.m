function cbPermutation = set_cbPermutation(exptName, setRow, permSavePath, population, bSubtract)
% Increments the count column of a given row by one. Should be called after get_cbPermutation
% It is possible to make this more flexible (see, for example, set_cbPermutation_timeAdapt) but for a standard
% call in experiments there should be no reason to increase the count by more or less than one. 
% 
% exptName: e.g. timeAdapt, vsaAdapt
% 
% setRow: the index of the row you want to change. (This will be the output number from get_cbPermutation)
% 
% permSavePath: The folder which contains the cbPermutation file. Typically
%               the same as your top level experiment path, i.e.,
%               /smng/experiment/(expt_name)/
% population: e.g. clinical, control. Use this if you have multiple populations and you're planning to counterbalance within
% population rather than across the whole experiment
%
% bSubtract: Set to 1 to DEcrement a row of the cbPermutation file.
% 

if nargin < 3 || isempty(permSavePath), permSavePath = cd; end
if nargin < 4 || isempty(population)
    populationStr = '';
else
    populationStr = strcat('_', population); %prepend underscore
end
if nargin < 5, bSubtract = 0; end

permFileName = strcat('cbPermutation_', exptName, populationStr, '.mat');
permFilePath = fullfile(permSavePath, permFileName);

if ~exist(permFilePath,'file')
    error('Did not find a file called %s in directory %s\n', permFileName, permSavePath); 
end

perms = load(permFilePath); 
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

save(permFilePath,'cbPermutation')

end