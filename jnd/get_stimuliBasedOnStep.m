function [stim1, stim2] = get_stimuliBasedOnStep(startPoint, stepSize, bSymmetrical)
% Function to get two numeric stimulus levels given a starting point, step size, and whether or not the starting point
% symmetrically splits the two stimuli
%
% Inputs: 
% 
%       startPoint:             The starting point for the stimuli. This should be a number. 
%
%       stepSize:               How far from each other the stimuli should be. Should also be a number. 
% 
%       bSymmetrical:           Whether the stimuli are equally spaced from the starting point. Defaults to 1. 
%           - bSymmetrical = 1: the distance between stim1 and stim2 is stepSize/2 
%           - bSymmetrical = 0: startpoint is set as stim1, and stim2 is stim1 + stepSize
% 
% Outputs:
%
%       stim1:                  The lower stimulus
%
%       stim2:                  The higher stimulus
% 
% Example:
%
% [stim1, stim2] = get_stimuliBasedOnStep(60, 80, 1); 
% Here the starting point forms the "center" of the stimuli, so stim1 = 20 and stim2 = 100
% 
% [stim1, stim2] = get_stimuliBasedOnStep(60, 80, 0); 
% Here the starting point is the low member of the stimuli, so stim1 = 60 and stim2 = 140
%
% Initiated RPK 2022/06/10 from Gorilla function from timitate

dbstop if error

%% Defaults

% startpoint (1) has no default
% stepSize (2) has no default
if nargin < 3 || isempty(bSymmetrical), bSymmetrical = 1; end

%%

if bSymmetrical
    halfStep = stepSize/2; 
    stim1 = startPoint - halfStep; 
    stim2 = startPoint + halfStep; 
else
    stim1 = startPoint; 
    stim2 = stim1 + stepSize; 
end


end