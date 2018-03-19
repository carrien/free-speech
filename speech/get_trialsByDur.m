function [trials,inds] = get_trialsByDur(dataVals,durRange)
%GET_TRIALSBYDUR  Get trials with durations inside a given range.

durations = [dataVals.dur];
inds = find(durations > durRange(1) & durations < durRange(end));
trials = [dataVals(inds).token];