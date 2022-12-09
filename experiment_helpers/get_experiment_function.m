function expFun = get_experiment_function(expName)
%For a given experiment name, return the function that runs that experiment

switch expName
    case 'stroopVOT'
        expFun = @run_speak_ptb;
    case 'colorName'
        expFun = @run_colorname_ptb;
    case 'uhdapter_down'
        expFun = @run_uhdapter_audapter_down;        
    case {'uhdapter' 'stress'}
        expFun = @run_uhdapter_audapter;
    case {'vsaAdapt', 'vsaAdapt2'}
        expFun = @run_vsaAdapt_audapter;
    case {'varModIn', 'varModOut', 'varModOut2', 'varModInOut'}
        expFun = @run_varMod_audapter;
    case 'varModMEG'
        expFun = @run_varMod_audapter_blocked;
    otherwise
        % see if there's a function with the format run_'expName'_audapter
        expFun = sprintf('run_%s_audapter', expName);
        isFunction = which(expFun);
        if isFunction
            fprintf(['No explicit function name found in list in get_experiment_function.m\n' ...
                'Using default behavior to set function name to %s\n'], expFun)
            expFun = eval(sprintf('@%s', expFun)); % convert from string to function_handle
        else
            fprintf('Function for experiment ''%s'' not found.',expName)
            expFun = [];
        end
end
