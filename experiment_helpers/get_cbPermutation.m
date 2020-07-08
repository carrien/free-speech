function [permIx,conditions] = get_cbPermutation(exptName, permsPath, population, permIx)
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

if nargin < 2 || isempty(permsPath), permsPath = get_exptLoadPath(exptName); end  
if nargin < 3, population = ''; end

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
lastCondCol = countCol-1; 

if nargin < 4 || isempty(permIx)
    permIx = find([cbPermutation{:,countCol}] == min([cbPermutation{:,countCol}]), 1); % Find the first row that has the min use
    conditions = cbPermutation(permIx, 1:lastCondCol); 
else 
    conditions = cbPermutation(permIx, 1:lastCondCol); 
end

end