function check_cbPerm_usage(exptName, IDList)

% if there are fewer than 2 input arguments or IDList is empty...
if nargin < 2 || isempty(IDList)
    %% grab all of the participant IDs from the experiment data folder
    % do this by getting the names of all the folders
    % exclude any folders that don't start with 'sp'
end

folderPath = get_exptLoadPath(exptName, 'acousticdata');
permIx_val = [];
cd (folderPath)
% make a loop that will load in each folder's expt.mat file
for id = IDList
    cd (id)
    load expt.mat
% within the loop, save the value of expt.permIx to a vector
    permIx_val(end+1,1) = expt.permIx;
    cd ..
% end loop
end
% Report on the number of times each permIx was used. For example,
% The permIx 2 was used 8 times, using a function like fprintf
[counts,inds] = groupcounts(permIx_val);
times_used = "";
for i=1:length(inds)
   times_used = times_used + fprintf("The permIx "+inds(i)+ " was used "+counts(i)+" times. ");
end

