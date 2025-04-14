function check_cbPerm_usage(exptName, IDList)

% if there are fewer than 2 input arguments or IDList is empty...
 if nargin < 2 || isempty(IDList)
    %% grab all of the participant IDs from the experiment data folder
    % do this by getting the names of all the folders
    % exclude any folders that don't start with 'sp'

    folderList = dir(get_exptLoadPath(exptName, 'acousticdata'));
    count = 1;
    for f = 1: length(folderList)
        folderCell = struct2cell(folderList(f));
        folderName = cell2mat(folderCell(1,:));
        if length(folderName) < 3
            fprintf(" a ")
            continue
        end
        fString = convertCharsToStrings(folderName);
        if extractBefore(fString, 3) == "sp"
           fprintf(" b ")
           fprintf(" "+count)
           IDList(:,count) = folderName;
           count = count + 1;
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

