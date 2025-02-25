function [permIx, permList, permLoadPath, permFileName] = get_cbPermutation(exptName, permLoadPath, population, permIx, allPermConds)
% Gets counterbalancing permutation info for a participant. Also creates
% the cbPermutation file if it doesn't exist yet.
%
% INPUT ARGUMENTS:
% exptName: Normally the value in expt.name. simonTone, vsaRetention. Used
%   to set permPath.
% permLoadPath: The path of the folder from which you want to load the
%   cbPermutation file.
% population: For studies where 'control' and 'patient', e.g., are tracked
%   separately. The value of `population` should exactly match what's in
%   the file name. So for "cbPermutation_patient.mat" the population is
%   'patient'.
% permIx: Optional. If you want to retrieve a particular permList from the
%   cbPermutation file, set permIx to the row number you want to retrieve.
% allPermConds: Optional. If you want to create the cbPermutation file if
%   it doesn't exist, then supply a cell array of all possible
%   conditions. Each row will be set to one condition. For example, a
%   cbPermutations file with three conditions and two elements per
%   condition could look like this.
%   {'Upshift' 'Noshift'; 'Downshift' 'Noshift'; 'Noshift' 'Noshift'}
%
% OUTPUT ARGUMENTS:
% permIx: Row number of cbPermutation used.
% permList: Full set of conditions for that permutation.
% permLoadPath: The path of the folder from which the cbPermutation
%   file was loaded.
% permFileName: The full name of the cbPermutation file loaded in.

% 2019 Robin Karlin initial coding
% 2021 Lana Hantzsch fix which row to pick
% 2025-02 Chris Naber various improvements

%% input arg handling
if nargin < 1 || isempty(exptName)
    error('Need exptName in input argument 1 for this function to run.')
end
if nargin < 2 || isempty(permLoadPath), permLoadPath = get_exptLoadPath(exptName); end  
if nargin < 3 || isempty(population)
    populationStr = '';
else
    populationStr = strcat('_', population); %prepend underscore
end
permFileName = strcat('cbPermutation_', exptName, populationStr, '.mat');

if nargin < 5
    allPermConds = [];
end

%% confirm filepath
% if specified permPath isn't accessible (eg server offline), change
% permPath to local default
if ~exist(permLoadPath, 'dir')
    permLoadPath_backup = get_exptLocalPath(exptName);
    if exist(permLoadPath_backup, 'dir')
        warning('Couldn''t access cbPermutation loadPath at %s. Switching to this path instead: %s.', permLoadPath, permLoadPath_backup);
    else
        error('Couldn''t access cbPermutation loadPath at %s. Backup load path at %s also did not exist.', permLoadPath, permLoadPath_backup);
    end
    permLoadPath = permLoadPath_backup;
end

permFilePath = fullfile(permLoadPath, permFileName);

% if permFile doesn't exist at permPath, try to make it
if ~exist(permFilePath, 'file')
    if ~isempty(allPermConds)
        warning('Since file %s was not found at %s, one was generated based on allPermConds.', permFileName, permLoadPath);
        gen_cbPermutation(permLoadPath, exptName, allPermConds, population);
    else
        error(['No file named %s exists at %s. Tried to generate that file, ' ...
            'but allPermConds input arg was not set.'], permFileName, permLoadPath);
    end
end

%% retrieve info from cbPerm file
perms = load(permFilePath); 
varField = fieldnames(perms); 
cbPermutation = perms.(char(varField));

[~,countCol] = size(cbPermutation); % Find the column that counts the number of uses
lastCondCol = countCol-1; 

if nargin < 4 || isempty(permIx)
    rng('shuffle')
    permInds = find([cbPermutation{:,countCol}] == min([cbPermutation{:,countCol}])); % Find rows with min use
    permIx = permInds(randperm(length(permInds), 1));   %get random index among rows with min use
end
permList = cbPermutation(permIx, 1:lastCondCol); 


end %EOF
