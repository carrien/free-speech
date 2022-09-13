function [] = validate_cbPermUsage(exptName, pop)
% TODO header

%% setup
acousticdata_folder = '\\wcs-cifs\wc\smng\experiments\simonMultisyllable\acousticdata\'; %TODO make dynamic
files = dir(acousticdata_folder);
dirFlags = [files.isdir];
dirs = files(dirFlags);
pp_list = {dirs(3:end).name};

subfolder_path = []; %optional


%% collect data from each expt file
cdCounter = [];
for ppIx = 1:length(pp_list)
    ppID = pp_list{ppIx};
    
    dataPath = fullfile(acousticdata_folder, subfolder_path, 'expt.mat'); %TODO fix this based on input args

    if isfile(fullfile(dataPath, 'expt.mat'))
        load(fullfile(dataPath, 'expt.mat'), 'expt')
        if isfield(expt, 'permIx')
            cdCounter = [cdCounter expt.permIx];                            %#ok<AGROW> 
        else
            warning('Couldn''t get permIx from %s because that field doesn''t exist', ppID)
        end
    else
        warning('Couldn''t load expt file for %s from filepath %s', ppID, dataPath)
    end
end


%% summary info
unique_list = unique(cdCounter);
count = [];
for i = 1:length(unique_list)
    count = [count length(find(cdCounter==unique_list(i)))];
end

% load in the counterbalancing file to find out what the indexes represent
if ~isempty(pop)
    pop = sprintf('_%s', pop); %prepend underscore before population name
end
cb_fileName = sprintf('cbPermutation_%s%s', exptName, pop)
load(fullfile(acousticdata_folder, '..', )) % TODO fix this



%summary_table = table(unique_list, count, ,   'VariableNames', {'value' 'count' 'rowNameInFile'}) %


