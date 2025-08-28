function [nextStepSize] = get_nextStepSize(expt, lastStepSize, bCorrect, nReversals)
% Function to get the next step size in an adaptive staircase based on staircase parameters set in expt and properties of the
% ongoing experiment. 
% 
% NOTE: this assumes a WEIGHTED UP-DOWN METHOD, where the step size changes on EVERY TRIAL. That is, a 3:1 ratio is
% satisfied by having the upstep 3x the size of the downstep, not by needing 3 correct trials in a row. 
% 
% Inputs: 
% 
%           expt:               an expt structure that has the following fields in it:
%               - maxStepSize:      the maximum difference between stimuli you will ever have in the experiment
%               - minStepSize:      the minimum difference between stimuli you will ever have in the experiment
%               - bigStepDelta:     the step differences at the beginning of the experiment. This is specified because some
%                                   experiments start with big deltas initially in order to rapidly get closer to the region 
%                                   of interest. 
%                                   If you want to use the same step deltas throughout, just set this to be the same as
%                                   smallStepDelta (see below), and set switchDelta to 0 
%               - switchDelta:      the number of reversals after which you would like to start using the more granualar step
%                                   size. E.g. if you specify 2, then on the 3rd reversal you will switch to using the
%                                   smaller step
%               - smallStepDelta:   the more granular step size, when people are more likely to be closer to their actual JND
%                                   and you would like to be more sensitive to differences here
%               - upDownMultiplier: the weighting ratio, e.g. 3 for 3:1, 2 for 2:1, etc. 
% 
%           lastStepSize:       the step size used in the previous trial
%
%           bCorrect:           whether the participant got the last trial correct or not
% 
%           nReversals:         the number of reversals incurred so far in the experiment. This is used to determine whether
%                               to use expt.bigStepDelta or expt.smallStepDelta 
% 
% Output:
% 
%           nextStepSize:       the next step size to be used in the experiment
% 
% Initiated RPK 2022-06-10 from Gorilla functions used in timitate 

dbstop if error

%% Determine the next step delta based on how far you are in the experiment
if nReversals <= expt.switchDelta
    % If you haven't gone through switchDelta reversals yet, use bigStepDelta (* ratio) 
    stepSizeDeltaDown = expt.bigStepDelta; 
    stepSizeDeltaUp = stepSizeDeltaDown * expt.upDownMultiplier; 
else
    % If you have been through switchDelta reversals, change in step size is now smallStepDelta (* ratio)
    stepSizeDeltaDown = expt.smallStepDelta; 
    stepSizeDeltaUp = stepSizeDeltaDown * expt.upDownMultiplier; 
end

%% Determine next step size based on correctness of answer
if bCorrect
    % If the last response was correct, the new step size should be lower by 1 step size change amount, except: 
    if lastStepSize - stepSizeDeltaDown < expt.minStepSize
        % If the last step size was the minimum step size (needs to stay there), or if you're so close to minimum that going 
        % down by stepSizeDeltaDown would go below the min 
        nextStepSize = expt.minStepSize; 
    else
        nextStepSize = lastStepSize - stepSizeDeltaDown; 
    end
    
else 
    % If the last response was incorrect, the new step size should be higher by stepSizeDeltaUp, except:     
    if stepSizeDeltaUp > expt.maxStepSize - lastStepSize 
        % If you are already at the max difference possible for the continuum, or so close to it that adding stepSizeDeltaUp
        % would surpass it
        nextStepSize = expt.maxStepSize; 
    else
        nextStepSize = lastStepSize + stepSizeDeltaUp; 
    end
    
end


end