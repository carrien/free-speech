function [sortedTrials] = get_sortedTrials(trialpath)
%GET_SORTEDTRIALS  Get sorted list of numbered matfiles in a directory.

w = what(trialpath);
matFiles = w.mat;

% Strip off '.mat' and sort
filenums = zeros(1,length(matFiles));
for i = 1:length(matFiles)
    [~, name] = fileparts(matFiles{i});
    filenums(i) = str2double(name);
end
sortedTrials = sort(filenums);

end

