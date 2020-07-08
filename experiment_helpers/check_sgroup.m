function [group] = check_sgroup(group,grouplist)

validstr = any(strcmp(group,grouplist)); % check if group exists in list
while ~validstr
    groupliststr = sprintf('%s ',grouplist{:});
    group = input(sprintf('Invalid group name. Please choose from %s: ',groupliststr),'s');
    validstr = any(strcmp(group,grouplist));
end