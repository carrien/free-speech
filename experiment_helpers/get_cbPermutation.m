function [permIx,conditions] = get_cbPermutation(exptName, permsPath, population, permIx, bLocalFallback, warnDataPath)
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
if nargin < 3 || isempty(population), population = ''; end
if nargin < 5 || isempty(bLocalFallback), bLocalFallback = 0; end


if isempty(population)
    permsFile = ['cbPermutation_' exptName '.mat']; 
else
    permsFile = ['cbPermutation_' exptName '_' population '.mat']; 
end

bUsedLocalFallback = 0;
if ~exist(fullfile(permsPath, permsFile),'file')
    if bLocalFallback
        warning('No counterbalancing file in this directory (%s) - trying local path instead...', permsPath);
        localPermsPath = get_exptLocalPath(exptName);
        if ~exist(fullfile(localPermsPath, permsFile),'file')
            error('No counterbalancing file in this local directory either (%s).', localPermsPath);
        else
            disp('Found local directory.')
            permsPath = localPermsPath;
        end
        bUsedLocalFallback = 1;
    else
        error('No counterbalancing file in this directory (%s)', permsPath);
    end
end

perms = load(fullfile(permsPath, permsFile)); 
varField = fieldnames(perms); 
cbPermutation = perms.(char(varField));

[nRows,countCol] = size(cbPermutation); % Find the column that counts the number of uses
lastCondCol = countCol-1; 

if bUsedLocalFallback
    permIx = randi(nRows); %get a random index from the set
end

rng('shuffle')
if nargin < 4 || isempty(permIx)
    permInds = find([cbPermutation{:,countCol}] == min([cbPermutation{:,countCol}])); % Find rows with min use
    permIx = permInds(randperm(length(permInds), 1));   %get random index among rows with min use
    conditions = cbPermutation(permIx, 1:lastCondCol); 
else 
    conditions = cbPermutation(permIx, 1:lastCondCol); 
end

% raise warning that includes permIx
if bUsedLocalFallback
    % TODO make sure this works
    warningFile = fullfile(warnDataPath,'cb_get_warning.txt');
    fid = fopen(warningFile, 'w');
    warning('Server did not respond. Using randomly generated permutation index: %d (see warning file)', permIx);
    fprintf(fid,'Server did not respond. Random permIx generated: %d', permIx);
    fclose(fid);
end

end %EOF
