function [permIx,conditions] = get_cbPermutation(exptName, permPath, population, permIx)
% Gets the index of the row you want to use for your participant for counterbalancing purposes and the
% conditions (in order) that that row has. 
% 
% exptName: e.g. timeAdapt, vsaAdapt
% 
% permsPath: should be the same as your experiment's server path such that is it is consistently updated even if people are running
% experiments nearly at the same time
% 
% population: e.g. clinical, control. Use this if you have multiple populations and you're planning to counterbalance within
% population rather than across the whole experiment
% 
% permIx: optional. If you can't connect to the server, you'll have determined permIx already; use this number to get the
% right conditions (added RPK 2/28/2020. Also bugfix to timeAdapt1) 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if nargin < 2 || isempty(permPath), permPath = get_exptLoadPath(exptName); end  
if nargin < 3 || isempty(population)
    populationStr = '';
else
    populationStr = strcat('_', population); %prepend underscore
end
permFile = strcat('cbPermutation_', exptName, populationStr, '.mat');

if ~exist(fullfile(permPath, permFile),'file')
    error('No counterbalancing file in this directory (%s)', permPath); 
end

perms = load(fullfile(permPath, permFile)); 
varField = fieldnames(perms); 
cbPermutation = perms.(char(varField));

[~,countCol] = size(cbPermutation); % Find the column that counts the number of uses
lastCondCol = countCol-1; 

rng('shuffle')
if nargin < 4 || isempty(permIx)
    permInds = find([cbPermutation{:,countCol}] == min([cbPermutation{:,countCol}])); % Find rows with min use
    permIx = permInds(randperm(length(permInds), 1));   %get random index among rows with min use
    conditions = cbPermutation(permIx, 1:lastCondCol); 
else 
    conditions = cbPermutation(permIx, 1:lastCondCol); 
end

end