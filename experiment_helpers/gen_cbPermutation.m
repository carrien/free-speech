function [] = gen_cbPermutation(permSavePath, exptName, conds, population)
%Generates a counterbalance tracking sheet for permutation combinations of
%given conditions

%permSavePath: directory path where counterbalance tracking table will be saved
    %Lab convention is to save this in SMNG/experiments/(expt_name)
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
if nargin <1 || isempty(permSavePath)
    permSavePath = get_exptLoadPath(exptName);
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
permFileName = strcat('cbPermutation_', exptName, populationStr, '.mat');
permFilePath = fullfile(permSavePath, permFileName);

if isfile(permFilePath)
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

    % add final column that will count the number of times a row is used
    [nRows, ~] = size(permTable);
    countList = num2cell(zeros(nRows, 1));

    %create table
    cbPermutation = horzcat(permTable, countList);
    save(permFilePath, 'cbPermutation');
end

end %EOF
