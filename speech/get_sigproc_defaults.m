function sigproc_params = get_sigproc_defaults(sigproc_params, bPrint)
%GET_SIGPROC_DEFAULTS Set missing values in the provided sigproc_params structure
%   GET_SIGPROC_DEFAULTS(SIGPROC_PARAMS)
%       Provided a sigproc_params structure, this function sets any of the
%       missing fields to a default value specified below. If an existing
%       sigproc_params is not provided, sigproc_params is created as an
%       empty struct, given the values from sigproc_params_default, and
%       returned.

if nargin < 1 || isempty(sigproc_params), sigproc_params = struct; end
if nargin < 2 || isempty(bPrint), bPrint = 1; end


sigproc_params_default = struct( ...
    'fs', 16000, ...
    'ms_framespec_gram', 'broadband', ...
    'ms_framespec_form', 'narrowband', ...
    'all_ms_framespecs', get_all_ms_framespecs(), ...
    'nfft', 4096, ...
    'nlpc', 13, ...
    'nlpc_choices', (7:20), ...
    'nformants', 2, ...
    'preemph', 0, ...
    'preemph_range', [-2 3], ...
    'pitchlimits', [50 300], ...
    'yes_smooth_amplitude', 0, ... % smooth the amplitude signal (takes a lot of time)
    'yes_autosetampl', 0, ... % automatically set the ampl for thresh value
    'indices2regress', 442, ... % number of indices to be used in the regressions for autosetting the amplitude
    'ampl_thresh4voicing', 0.0271, ... % manual amplitude threshold; tracks at time points below thresh are set to NaNs
    'wave_viewer_logshim', 1, ...   % makes 20*log10(0 + wave_viewer_logshim) = 0
    'yes_just_thresh',0, ... % used by set_edit_ampl_threshold to signify that we only are changing the threshold and don't need to recalculate
    'ftrack_method','praat');

fields = fieldnames(sigproc_params_default);
for f = 1:length(fields)
    fieldname = fields{f};
    sigproc_params = set_missingField(sigproc_params,fieldname,sigproc_params_default.(fieldname), bPrint);
end

gui_params = struct('yes_create_hplayer', 1, ...
    'yes_gray', 1, ... % do you want the spectogram to be gray or blue with red marked as intensity. (also flipped upside down)
    'thresh_gray', 0, ... % for the spectogram of the formants.
    'max_gray', 1, ... % for the spectogram of the formants.
    'dummy_param','test');