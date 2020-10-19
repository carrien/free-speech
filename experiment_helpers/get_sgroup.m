function [group, iGroup] = get_sgroup(subjPath,groups)
%GET_SGROUP Randomly chooses subject group, excluding already-existing groups.

if nargin < 1 || isempty(subjPath), subjPath = pwd; end
if nargin < 2 || isempty(groups), error('Must input at least one group.'); end

unusedGroups = get_unusedDirs(subjPath,groups);
if isempty(unusedGroups)
    group = input('All groups already exist as folders for this subject! Please enter a group name: ', 's');
    group = check_sgroup(group, groups); % check that group is valid
    iGroup = find(strcmp(group,groups));
else
    rng('shuffle'); % initialize generator based on current time
    rp = randperm(length(unusedGroups));
    group = unusedGroups{rp(1)};
    iGroup = find(strcmp(group,groups));
end

end
