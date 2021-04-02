function expFun = get_experiment_function(expName)
%For a given experiment name, return the function that runs that experiment

switch expName
    case 'noisyfb'
        expFun = @run_noisyfb_audapter;
    case 'stroopVOT'
        expFun = @run_speak_ptb;
    case 'colorName'
        expFun = @run_colorname_ptb;
    case 'uhdapter'
        expFun = @run_uhdapter_audapter;
    case 'uhdapter_down'
        expFun = @run_uhdapter_audapter_down;        
    case 'stress'
        expFun = @run_uhdapter_audapter;
    case 'vin'
        expFun = @run_vin_audapter;
    case 'vinRep'
        expFun = @run_vinRep_audapter;
    case 'sAdapt'
        expFun = @run_sAdapt_audapter;
    case {'vsaAdapt', 'vsaAdapt2'}
        expFun = @run_vsaAdapt_audapter;
    case {'varModIn', 'varModOut', 'varModOut2', 'varModInOut'}
        expFun = @run_varMod_audapter;
    case 'timeAdapt'
        expFun = @run_timeAdapt_audapter; 
    case 'cif1'
        expFun = @run_cif1_audapter;
    case 'vsaGeneralize'
        expFun = @run_vsaGeneralize_audapter;
    case 'attentionComp'
        expFun = @run_attentionComp_audapter;
    otherwise
        fprintf('Function for experiment ''%s'' not found.',expName)
        expFun = [];
end
