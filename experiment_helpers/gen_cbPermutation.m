function [] = gen_cbPermutation(dataPath, exptName, conds, population)
%Generates a counterbalance tracking sheet for permutation combinations of
%given conditions

%dataPath: dataPath where counter balance tracking table will be saved
%exptName: name of experiment
%conds: what conditions are being counterbalanced
    %this could include words (e.g. {'bead', 'bad', 'bed'})
    %or group assignment order (e.g. {'control', 'shifted'})
%population: name of separate populations (e.g. 'control' or 'clinical')
    %or you can use this field if you want separate tracking for groups (i.e. 'control' or 'perturbed') in the study
%%
if nargin < 4 || isempty(population)
    bPopulation = 0;
else
    bPopulation = 1;
end

%% check if permutation file already exists
if bPopulation
    permsFile = fullfile(dataPath, ['cbPermutation_' exptName '_' population '.mat']); 
else
    permsFile = fullfile(dataPath, ['cbPermutation_' exptName '.mat']); 
end

if isfile(permsFile) 
    bGenerate = input('Are you sure you want to generate this permutation file? This will overwrite an existing file! (y/n): ', 's'); 
else 
    bGenerate = 'y';
end

%% create perms table
if strcmp(bGenerate, 'y')
    %set up word permutation
    permTable = perms(conds);
    nperms = length(permTable);
    %set count column
    countList = num2cell(zeros(nperms, 1)); %needs to be converted before concatinated

    %create table
    permsFile = horzcat(permTable, countList);
    if bPopulation
        save(fullfile(dataPath, ['cbPermutation_' exptName '_' population '.mat']), 'permsFile')
    else
        save(fullfile(dataPath, ['cbPermutation_' exptName '.mat']), 'permsFile')
    end
end

end
        
    
