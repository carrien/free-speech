function varargout = calcPertValue(behavior,param1,value1,param2,value2)
% UPDATE: 
% 
% This function calculates a desired value based on two known values. It can calculate: 
% --- the necessary rate1, given dur1 and the total perturbation; 
% --- the necessary dur1, given rate1 and the total perturbation; 
% --- the resulting perturbation, given rate1 and dur1. 
% 
% This calculation must be performed whenever there is an absolute value
% for how long a slow-down event should last. If you wish the slow-down event 
% to introduce 60 ms of delay, you cannot simply put 0.06 in the dur1
% parameter in the PCF file. The Audapter settings perform time warping on
% a sample for duration dur1 which is played back at rate1 speed.
%
%
% Input arguments:
% 1.) behavior (thing to get). 'dur1' or 'perturb' or 'rate1'
% 2.) param1: the name of the first known parameter. Currently supports 'dur1' 'rate1' 'perturb' 
% 3.) value1: the value of param1
% 4.) param2: the name of the second known parameter.
% 5.) value2: the value of param2
% 
% (This structure is used so that you do not have to strictly order your arguments) 
%
% Last updated RPK 2019/9/25

components = struct(); 

components.(param1) = value1;
components.(param2) = value2; 

switch behavior
    case 'dur1'
        necParams = {'rate1' 'perturb'};
    case 'rate1'
        necParams = {'dur1' 'perturb'};
    case 'perturb'
        necParams = {'dur1' 'rate1'}; 
end

if ~isfield(components,necParams{1}) || ~isfield(components,necParams{2})
    error(['To calculate ' upper(behavior) ', you need ' upper(necParams{1}) ' and ' upper(necParams{2}) '.'])
end

if strcmp(behavior,'dur1') % dur1 needs perturb and speed
    dur1 = components.perturb / (1 - components.rate1);
    varargout{1} = dur1;
end

if strcmp(behavior,'rate1') % rate1 needs perturb and dur1
    rate1 = 1 - (components.perturb / components.dur1); 
    varargout{1} = rate1;    
end

if strcmp(behavior,'perturb') % totalDur needs rate1 and dur1
    % Fixed 5/5/2021 RK 
    perturb = components.dur1 - (components.rate1 * components.dur1); 
    varargout{1} = perturb; 
end

end