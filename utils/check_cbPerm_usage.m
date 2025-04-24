function check_cbPerm_usage(exptName, IDList)

% if there are fewer than 2 input arguments or IDList is empty...
 if nargin < 2 || isempty(IDList)
    %% grab all of the participant IDs from the experiment data folder
    % do this by getting the names of all the folders
    % exclude any folders that don't start with 'sp'

    % get list of names of folders in experiment data folder
    folderList = dir(get_exptLoadPath(exptName, 'acousticdata'));
    % initialize an index variable that has the index for the next value in
    % the ID list
    index = 1;
    % loop through list of names 
    for f = 1: length(folderList)
        folderCell = struct2cell(folderList(f));
        folderName = cell2mat(folderCell(1,:));
        % skip to next folder name if the length of the folder name is less
        % than three characters
        if length(folderName) < 3
            continue
        end
        stringName = string(folderName);
        % check if the first two characters are sp and if so add it to the
        % ID list

        % TODO make this work if the start of the participant ID is any of
        % 'sp', 'pd' (example experiment: vsaPD), or 'ca' (example experiment: cerebAAF)
        if extractBefore(stringName, 3) == "sp"
            endNum = str2double(extractBetween(stringName, strlength(stringName)-2, strlength(stringName),"Boundaries","inclusive"));
            if ~(isnan(endNum))
               IDList(1,index) = stringName;
               index = index + 1;
           end
        end
    end

end

folderPath = get_exptLoadPath(exptName, 'acousticdata');
permIx_val = [];

% TODO rather than actually cd'ing to the folder path, just load in the
% expt file without cd'ing. This almost means you don't need cd .. later
% make a loop that will load in each folder's expt.mat file
for id = IDList
    load (fullfile(folderPath,id,'expt.mat'),'expt')
    if ~(isfield(expt, 'permIx'))
        fprintf("There is no permIx for "+id+". Skipping to next participant.\n")
        continue
    end
    permIx_val(end+1,1) = expt.permIx; %#ok<AGROW> 
end

% Report on the number of times each permIx was used. For example,
% The permIx 2 was used 8 times, using a function like fprintf
[counts,inds] = groupcounts(permIx_val);
times_used = "";
for i=1:length(inds)
    times_used = times_used + fprintf("The permIx "+inds(i)+ " was used "+counts(i)+" times. \n");
end

%% compare usage counts in cbPermutation.mat vs expt files

% TODO make this work for experiments where the cbPermutation file name is
% different. See for example, vsaPD, where there are files called
% 'cbPermutation_vsaPD_clinical.mat' and 'cbPermutation_vsaPD_control.mat'.
% It would be nice if this script could present the user a list of all the
% files whose name starts with 'cbPermutation', and the user picks the
% right file. Something like:
%
%   There is/are [2] file(s) which start with 'cbPermutation' within [filepath]
%   Which of these files should be used?
%       cbPermutation_vsaPD_clinical
%       cbPermutation_vsaPD_control
% >> cbPermutation_vsaPD_control
%
% OR
%
%   There is/are [0] file(s) which start with 'cbPermutation' within [filepath]
%   Therefore, I cannot compare usage counts between expt files and a cbPermutation file.
%
% Use the function AskNChoiceQuestion to properly handle user text
% entry for defined options.

cbPermFiles = {};
exptPath = get_exptLoadPath(exptName);
exptFolders = dir(exptPath);
i = 1;
for e = 1:length(exptFolders)
   exptCell = struct2cell(exptFolders(e));
   exptFile = cell2mat(exptCell(1,:));
   exptFileString = string(exptFile);
   if length(exptFile) < 14
       continue
   end
   if extractBefore(exptFileString,14) == "cbPermutation"
       cbPermFiles{i} = char(exptFileString); %#ok<AGROW> 
       i = i+1;
   end
end
if isempty(cbPermFiles)
    fprintf("There are 0 files which start with cbPermutation within "+exptPath+". Therefore, I cannot compare usage counts between expt files and a cbPermutation file.")
else
    if length(cbPermFiles) == 1
        % TODO announce to user which cbPerm file is being used
        stringResponse = cbPermFiles{1};
    else
        fprintf("There is/are "+length(cbPermFiles)+" file(s) which start with cbPermutation within "+exptPath+".")
        response = askNChoiceQuestion('Which of these choices should be used?',cbPermFiles);
        stringResponse = string(response);
    end


    % load cbPermutation file
    load(fullfile(get_exptLoadPath(exptName), stringResponse),'cbPermutation')

    % loop through the rows of cbPermutation to compare with counts variable
    % from check_cbPerm_Usage()

    % TODO if the counts don't match, report the counts of each.
    for r = 1:size(cbPermutation, 1)
        if ~(cbPermutation{r, 3}==counts(r))
            fprintf("The counts in the cbPermutation file do not match up to the counts from check_cbPerm_usage for permIx "+inds(r)+".")
        else
            % TODO if the counts DO match, report that as well.
        end
    end
end

