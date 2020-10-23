function  checkTrials  = get_missingTrials(temp)
%GET_MISSINGTRIALS finds missing trials in trials directory

if nargin < 1 || isempty(temp), temp = dir('trials/'); end


load('expt.mat')


%create trialList to contain all trial numbers in trials directory
nfiles = length(temp);
for i = 3:nfiles
    trialList(i-2) = str2double(temp(i).name(1:end-4));
end

%sort trial list
trialList = sort(trialList);

%create a numerical list from 1 to expt.ntrials (number of trials)
allTrials = 1:expt.ntrials;

%find missing trials and save to checkTrials
checkTrials = setdiff(allTrials,trialList)

end

