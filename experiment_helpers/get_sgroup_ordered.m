function [group, iGroup] = get_sgroup_ordered(subjPath,groups)
%GET_SGROUP chooses subject group, excluding already-existing groups.

if nargin < 1 || isempty(subjPath), subjPath = pwd; end
if nargin < 2 || isempty(groups), error('Must input at least one group.'); end

unusedGroups = get_unusedDirs(subjPath,groups);
if isempty(unusedGroups)
    %TODO: handle the case where both folders already exist and we don't
    %want to overwrite the contents of either (add 'session3'?)
    display(groups);
    group = input('All groups already exist as folders for this subject! Please enter a group name: ', 's');
   
    group = check_sgroup(group, groups); % check that group is valid
    iGroup = find(strcmp(group,groups));
else
    %rp = randperm(length(unusedGroups));
    group = unusedGroups{1};
    iGroup = find(strcmp(group,groups));
end

end
