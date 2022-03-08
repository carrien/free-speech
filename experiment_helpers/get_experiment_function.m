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
    case 'varModMEG'
        expFun = @run_varMod_audapter_blocked;
    case 'timeAdapt'
        expFun = @run_timeAdapt_audapter; 
    case 'cif1'
        expFun = @run_cif1_audapter;
    case 'vsaGeneralize'
        expFun = @run_vsaGeneralize_audapter;
    case 'attentionComp'
        expFun = @run_attentionComp_audapter;
    case 'simonSingleWord'
        expFun = @run_simonSingleWord_audapter;
    case 'taimComp'
        expFun = @run_taimComp_audapter;        
    case 'coAdapt'
        expFun = @run_coAdapt_audapter;
    case 'attentionAdapt'
        expFun = @run_attentionAdapt_audapter;
    case 'simonMultisyllable'
        expFun = @run_simonMultisyllable_audapter;
    case 'simonMultisyllable_v2'
        expFun = @run_simonMultisyllable_v2_audapter;
    case 'simonToneLex'
        expFun = @run_simonToneLex_audapter;
    case 'simonSyllableTransfer'
        expFun = @run_simonSyllableTransfer_audapter;
    case 'noGoAdapt'
        expFun = @run_noGoAdapt_audapter;
    otherwise
        fprintf('Function for experiment ''%s'' not found.',expName)
        expFun = [];
end
