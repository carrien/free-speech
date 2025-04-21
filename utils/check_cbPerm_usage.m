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
    load (fullfile(folderPath,id,'expt.mat'),'expt') % TODO address matlab warning. something like load('expt.mat', 'expt')
% TODO check if permIx exists in expt and if not print a warning
% and skip to the next participant
if ~(isfield(expt, 'permIx'))
    fprintf("There is no permIx for "+id+".")
    continue
end
% within the loop, save the value of expt.permIx to a vector
    permIx_val(end+1,1) = expt.permIx; %#ok<AGROW> 
% end loop
end
% Report on the number of times each permIx was used. For example,
% The permIx 2 was used 8 times, using a function like fprintf
[counts,inds] = groupcounts(permIx_val);
times_used = "";
for i=1:length(inds)
    % TODO add newlines (via /n ) to fprintf
   times_used = times_used + fprintf("The permIx "+inds(i)+ " was used "+counts(i)+" times. \n");
end
%% TODO load in the cbPermutation file and see if the counts in the cbPermutation file match up to the counts obtained from check_cbPerm_usage
% load cbPermutation file
load(fullfile(get_exptLoadPath(exptName), 'cbPermutation_'+exptName+'.mat'),'cbPermutation')
% loop through the rows of cbPermutation to compare with counts variable
% from check_cbPerm_Usage()
for r = 1:size(cbPermutation, 1)
    if ~(cbPermutation{r, 3}==counts(r))
        fprintf("The counts in the cbPermutation file do not match up to the counts from check_cbPerm_usage for permIx "+inds(r)+".")
    end
end

