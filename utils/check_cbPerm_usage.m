function check_cbPerm_usage(dataFolder, cbPermPath, dataFolder_subfolder, IDList)
% A utility for checking the accuracy of counterbalancing permutation
% usage for an experiment. Each participant's expt.mat file keeps track of
% which counterbalancing permutation instance they used, in expt.permIx.
% (Note that this field doesn't exist for experiments without
% counterbalancing.) The cbPermutation file also tracks how many times a
% permutation was used. This utility compares the numbers to make sure they
% align. 
%
% Input arguments:
%   dataFolder: The path of the folder with the participant IDs. Typically
%     something like:
%     '\\wcs-cifs\wc\smng\experiments\[exptName]\acousticdata\'
%   cbPermPath: The full file path of the counterbalancing file for
%     comparison. Typically it will be something like:
%     '\\wcs-cifs\wc\smng\experiments\[exptName]\cbPermutation.mat'
%   dataFolder_subfolder: [OPTIONAL] For most experiments, this can be left
%     blank. If within a participant's data folder, there is another
%     subfolder(s) before you get to the actual expt.mat file, set this to
%     the subfolder(s) between dataFolder and expt.mat. For example,
%     if your experiment stores data like this:
%         \experiments\[exptName]\acousticdata\sp123\Task1\Part1\expt.mat
%     Then set dataFolder_subfolder to 'Task1\Part1'
%   IDList: [OPTIONAL] A cell array of "good" participant IDs you want
%     to count for counterbalancing purposes. This may not be all of the
%     participants who completed the experiment if, eg, you know a certain
%     participant will be excluded from data analysis, or didn't finish the
%     whole experiment. If left blank, this script will try to collect all
%     IDs programmatically.

if nargin < 2 || isempty(dataFolder) || isempty(cbPermPath)
    error('Input args 1 and 2 are mandatory. See header for details.');
end
if nargin < 3
    dataFolder_subfolder = [];
end
if nargin < 4
    IDList = {};
end

%% set IDList if not sent by user
if nargin < 4 || isempty(IDList)
    % get list of names of folders
    folderList = dir(dataFolder);
    folderNames = {folderList.name};
    
    % narrow down folder names to only participant IDs
    [~, IDList] = isParticipantID(folderNames);
end

if isempty(IDList)
    error(['No participants could be identified for this experiment based on ' ...
        'folder names in the dataFolder directory. Does this experiment use a ' ...
        'different naming convention for participant IDs? Consider setting ' ...
        'the IDList input argument manually.'])
end

%% Load expt.mat files and count permIx usages
permIx_values = []; % initialize vector for counting permIx
IDList_good = {};   % initialize cell array for good participant IDs
for id_ix = 1:length(IDList)
    id = IDList{id_ix}; % convert back from cell to char array
    exptFilePath = fullfile(dataFolder, id, dataFolder_subfolder, 'expt.mat');
    dataFilePath = fullfile(dataFolder, id, dataFolder_subfolder, 'data.mat');
    if exist(exptFilePath, 'file') == 0
        fprintf('! No expt.mat file at %s. Skipping to next participant.\n', exptFilePath)
        continue
    end
    
    if exist(dataFilePath, 'file') == 0
        fprintf('! No data.mat file at %s. Skipping to next participant.\n', dataFilePath)
        continue
    end

    % old experiments use expt.permIx, newer experiments use expt.cbPerm.ix
    load(exptFilePath, 'expt')
    if ~(isfield(expt, 'permIx')) && ~(isfield(expt, 'cbPerm') && isfield(expt.cbPerm, 'ix'))
        fprintf('! No expt.permIx field nor expt.cbPerm.ix field for %s. Skipping to next participant.\n', id)
        continue
    end

    % Append values for later tabular display
    if isfield(expt, 'permIx')
        permIx = expt.permIx;
    elseif isfield(expt, 'cbPerm')
        permIx = expt.cbPerm.ix;
    end
    permIx_values(end+1,1) = permIx; %#ok<*AGROW>
    IDList_good{end+1,1} = id;
end

% Create and display table after loop
resultsTable = table(IDList_good, permIx_values, 'VariableNames', {'ParticipantID', 'permIx'});
disp(resultsTable);

% Report the number of times each permIx was used
[exptCount_numUsages, exptCount_inds] = groupcounts(permIx_values);
for i=1:length(exptCount_inds)
    fprintf('permIx %d was used %d times. \n', exptCount_inds(i), exptCount_numUsages(i));
end

%% compare usage counts in cbPermutation.mat vs expt files

% verify that the user-supplied cbPermutation file exists
cbPermPath_exists = exist(cbPermPath, 'file');
if cbPermPath_exists == 0 % doesn't exist
    error('Couldn''t access the specified cbPermPath or it doesn''t exist: %s. Check that you set the cbPermPath input argument correctly.', cbPermPath);
elseif cbPermPath_exists ~= 2 % not a file
    error('You specified cbPermPath as %s but cbPermPath should be a file. Check that you set the cbPermPath input argument correctly.', cbPermPath);
end

% load cbPermutation file
load(cbPermPath, 'cbPermutation') % assumes that the variable loaded in is called cbPermutation

cbPerm_nRows = size(cbPermutation, 1);
cbPerm_nCols = size(cbPermutation, 2);

% concatenate the names/values from each row in the cbPerm file
for i_permRow = 1:cbPerm_nRows
    permNames{i_permRow} = '';
    for i_permElement = 1:cbPerm_nCols-1
        if isnumeric(cbPermutation{i_permRow, i_permElement})
            permNames{i_permRow} = sprintf('%s%d, ', permNames{i_permRow}, cbPermutation{i_permRow, i_permElement});
        else % assume string
            permNames{i_permRow} = sprintf('%s%s, ', permNames{i_permRow}, cbPermutation{i_permRow, i_permElement});
        end
    end
    permNames{i_permRow} = permNames{i_permRow}(1:end-2); % strip off last comma and space
end

% set up values that will populate table
t_permIx_value = (1:size(cbPermutation, 1))';
t_perm_names = permNames';
t_numUsages_cbPerm = [cbPermutation{:, size(cbPermutation, 2)}]';
t_numUsages_expt = zeros(cbPerm_nRows, 1);
for i = 1:length(exptCount_inds)
    t_numUsages_expt(exptCount_inds(i), 1) = exptCount_numUsages(i);
end

% make table
countTable = table(t_permIx_value, t_perm_names, t_numUsages_cbPerm, t_numUsages_expt);

% set table column names
countTable.Properties.VariableNames = ["PermIx value", "Perm names/values"...
    "# of usages in cbPermutation", "# of usages in expt.mat files"];

% display table to user
disp(countTable)

% display message about changing cbPerm file
disp('If you want to edit the counts in the cbPermutation file, consider using the functionset_cbPermutation.')

end %EOF
