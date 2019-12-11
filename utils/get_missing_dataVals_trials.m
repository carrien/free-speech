function [missing] = get_missing_dataVals_trials(subjdP,nTrials)

trialdir = fullfile(subjdP,'trials');

mytrials = dir(trialdir);
names = {mytrials.name};
missing = cell(1,nTrials);

for n = 1:nTrials
    matname = [num2str(n) '.mat'];
    if ~any(strcmp(names,matname))
        missing{n} = matname;
    end
end

missing = missing(~cellfun('isempty',missing))