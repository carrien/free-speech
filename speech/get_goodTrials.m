function goodTrials = get_goodTrials(dataVals)
%function to create list of trial indices marked as 'good' from the
%dataVals file. When running signalOut data analysis, then use this list of
%good trials to run waverunner without getting error - i.e. waverunner([],
%goodTrials, 'signalOut', 0)

goodTrials = [];
for i = 1:length(dataVals)
   if dataVals(i).bExcl == 0 
       goodTrials = [goodTrials dataVals(i).token];
   end
end