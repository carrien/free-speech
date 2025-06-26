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
%     particpiant will be excluded from data analysis, or didn't finish the
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

    % initialize an index variable for the next value in the ID list
    i_ID = 1;

    % loop through list of folder names
    for i_folder = 1: length(folderList)
        folderCell = struct2cell(folderList(i_folder));
        folderName = cell2mat(folderCell(1,:));

        % skip folder if name is less than 3 characters
        if length(folderName) < 3
            continue
        end

        % if the first two characters match typical participant ID names, include it
        ppID_startChars = {'sp', 'pd', 'ca'};
        firstTwo = extractBefore(folderName, 3);
        if contains(firstTwo, ppID_startChars)
            endNum = str2double(extractBetween(folderName, strlength(folderName)-2, strlength(folderName),'Boundaries','inclusive'));
            if ~(isnan(endNum))
                IDList(i_ID) = {folderName}; % save folderNames as cells in cell array
                i_ID = i_ID + 1;
            end
        end
    end
end

if isempty(IDList)
    error(['No participants could be identified for this experiment based on ' ...
        'folder names in the dataFolder directory. Does this experiment use a ' ...
        'different naming convention for participant IDs? Consider setting ' ...
        'the IDList input argument manually.'])
end

%% Load expt.mat files and count permIx usages
permIx_values = []; % initialize vector for counting permIx
for id_ix = 1:length(IDList)
    id = IDList{id_ix}; % convert back from cell to char array
    exptFilePath = fullfile(dataFolder, id, dataFolder_subfolder, 'expt.mat');
    if exist(exptFilePath, 'file') == 0
        fprintf('There is no expt.mat for '+id+'. Skipping to next participant.\n')
        continue
    end
    load(exptFilePath, 'expt')
    if ~(isfield(expt, 'permIx'))
        fprintf('There is no permIx for '+id+'. Skipping to next participant.\n')
        continue
    end

    fprintf('For participant %s, permIx value %d\n', id, expt.permIx);
    permIx_values(end+1,1) = expt.permIx; %#ok<AGROW>
end

% Report the number of times each permIx was used
% TODO rename variables counts and inds
[counts,inds] = groupcounts(permIx_values);
for i=1:length(inds)
    fprintf('The permIx %d was used %d times. \n', inds(i), counts(i));
end

%% compare usage counts in cbPermutation.mat vs expt files

% verify that the user-supplied cbPermutation file exists
if exist(cbPermPath, 'file') == 0
    error('Couldn''t load a file called %s. Check that you set the cbPermPath input argument correctly.', cbPermPath);
end

% load cbPermutation file
load(cbPermPath, 'cbPermutation') % assumes that the variable loaded in is called cbPermutation

% TODO split table columns out to separate variables for visibility

% TODO add another table column that concatenates the first several columns
% of cbPerm into one thing, showing what the cbPerm strings were
countTable = table((1:size(cbPermutation, 1))', [cbPermutation{:, size(cbPermutation, 2)}]', counts);

% TODO rename table column headers
countTable.Properties.VariableNames = ["PermIx", "cbPermutation", "Participants' expt.mat files"];

% display table to user
countTable %#ok<NOPRT> 


end %EOF
