function [permIx, permList, permPath] = get_cbPermutation(exptName, permPath, population, permIx, allPermConds)
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

% TODO update header

%% input arg handling
if nargin < 1 || isempty(exptName)
    error('Need exptName in input argument 1 for this function to run.')
end
if nargin < 2 || isempty(permPath), permPath = get_exptLoadPath(exptName); end  
if nargin < 3 || isempty(population)
    populationStr = '';
else
    populationStr = strcat('_', population); %prepend underscore
end
permFile = strcat('cbPermutation_', exptName, populationStr, '.mat');
if nargin < 5
    allPermConds = [];
end

%% confirm filepath
% if specified permPath isn't accessible (eg server offline), change
% permPath to local default
if ~exist(permPath, 'dir')
    permPath = get_exptLocalPath(exptName);
end

% if permFile doesn't exist at permPath, try to make it
if ~exist(fullfile(permPath, permFile), 'file')
    if ~isempty(allPermConds)
        gen_cbPermutation(permPath, exptName, allPermConds, population);
    else
        error(sprintf(['No file named %s exists at %s. Tried to generate that file, ' ...
            'but allPermConds input arg was not set.'], permFile, permPath)) %#ok<SPERR> 
    end
end

%% retrieve info from cbPerm file
perms = load(fullfile(permPath, permFile)); 
varField = fieldnames(perms); 
cbPermutation = perms.(char(varField));

[~,countCol] = size(cbPermutation); % Find the column that counts the number of uses
lastCondCol = countCol-1; 

rng('shuffle')
if nargin < 4 || isempty(permIx)
    permInds = find([cbPermutation{:,countCol}] == min([cbPermutation{:,countCol}])); % Find rows with min use
    permIx = permInds(randperm(length(permInds), 1));   %get random index among rows with min use
    permList = cbPermutation(permIx, 1:lastCondCol); 
else 
    permList = cbPermutation(permIx, 1:lastCondCol); 
end

end %EOF
