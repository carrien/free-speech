function cbPermutation = set_cbPermutation(exptName, setRow, permsPath, population)
% Increments the count column of a given row by one. Should be called after get_cbPermutation
% It is possible to make this more flexible (see, for example, set_cbPermutation_timeAdapt) but for a standard
% call in experiments there should be no reason to increase the count by more or less than one. 
% 
% exptName: e.g. timeAdapt, vsaAdapt
% 
% setRow: the index of the row you want to change. (This will be the output number from get_cbPermutation)
% 
% permsPath: should be the same as your experiment path (top level) 
% population: e.g. clinical, control. Use this if you have multiple populations and you're planning to counterbalance within
% population rather than across the whole experiment
% 

if nargin < 3 || isempty(permsPath), permsPath = cd; end
if nargin < 4, population = ''; end

if isempty(population)
    permsFile = ['cbPermutation_' exptName '.mat']; 
else
    permsFile = ['cbPermutation_' exptName '_' population '.mat']; 
end

if ~exist(fullfile(permsPath, permsFile),'file')
    error('No counterbalancing file in this directory (%s)', permsPath); 
end

perms = load(fullfile(permsPath, permsFile)); 
varField = fieldnames(perms); 
cbPermutation = perms.(char(varField));

[~,countCol] = size(cbPermutation); % Find the column that counts the number of uses
currentCount = cbPermutation{setRow,countCol}; 
newCount = currentCount + 1; 
cbPermutation{setRow,countCol} = newCount; 

save(fullfile(permsPath, permsFile),'cbPermutation')

end