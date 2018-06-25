function [sortedTrialnums,sortedTrialnames] = get_sortedTrials(trialpath)
%GET_SORTEDTRIALS  Get sorted list of numbered matfiles in a directory.

w = what(trialpath);
matFiles = w.mat;

% Strip off '.mat' and sort trial numbers
filenums = zeros(1,length(matFiles));
for i = 1:length(matFiles)
    [~, name] = fileparts(matFiles{i});
    filenums(i) = str2double(name);
end
[sortedTrialnums,idx] = sort(filenums);

% Sort trial names in the same order
sortedTrialnames = matFiles(idx);

end
