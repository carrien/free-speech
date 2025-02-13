function [] = gen_cbPermutation(dataPath, exptName, conds, population)
%Generates a counterbalance tracking sheet for permutation combinations of
%given conditions

%dataPath: dataPath where counter balance tracking table will be saved
    %Lab convention is to save this in SMNG/experiments/(exp_name)
%exptName: name of experiment
%conds: what conditions are being counterbalanced
    %this could include words (e.g. {'bead', 'bad', 'bed'})
    %or group assignment order (e.g. {'control', 'shifted'})
    
    % if conds is a cell array with multiple rows,
    % e.g. {'a' 'a'; 'a' 'b'; 'a' 'c'; 'a' 'd'}
    % then `conds` is considered to be the complete set of permutations
%population: name of separate populations (e.g. 'control' or 'clinical')
    %or you can use this field if you want separate tracking for groups (i.e. 'control' or 'perturbed') in the study
%%
if nargin <1 || isempty(dataPath)
    dataPath = fullfile(get_exptLoadPath, exptName);
end

[nRowsConds, ~] = size(conds);
if nRowsConds > 1
    bCompleteSetofConds = 1;
else
    bCompleteSetofConds = 0;
end

if nargin < 4 || isempty(population)
    populationStr = '';
else
    populationStr = strcat('_', population); %prepend underscore
end

%% check if permutation file already exists
filename = strcat('cbPermutation_', exptName, populationStr, '.mat');
permFile = fullfile(dataPath, filename); 

if isfile(permFile) 
    bGenerate = askNChoiceQuestion('Are you sure you want to generate this permutation file? This will overwrite an existing file!'); 
else 
    bGenerate = 'y';
end

%% create perms table
if strcmp(bGenerate, 'y')
    % make full set of permutation conditions, one condition per row
    if bCompleteSetofConds
        permTable = conds;
    else
        permTable = perms(conds);
    end

    % make column that will count the number of times a row is used
    [nRows, ~] = size(permTable);
    countList = num2cell(zeros(nRows, 1));

    %create table
    permFile = horzcat(permTable, countList);
    cbPermutation = permFile; %rename variable for saving
    save(fullfile(dataPath, strcat('cbPermutation_', exptName, populationStr, '.mat')), 'cbPermutation');
end

end %EOF
