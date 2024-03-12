function [sigmat] = wave_proc(y,sigproc_params,params2track)
%WAVE_PROC  Run acoustic processing on a speech waveform.
%   WAVE_PROC(Y,SIGPROC_PARAMS,PARAMS2TRACK) processes the acoustic signal
%   in Y according to the parameters in SIGPROC_PARAMS and returns a
%   structure SIGMAT whose fields are the tracks specified in PARAMS2TRACK.
%
%   (shouldn't need plot_params because no plotting here)
%   only sets certain fields of sigmat determined by params2track

if nargin < 2 || isempty(sigproc_params), sigproc_params = get_sigproc_defaults; end
if nargin < 3 || isempty(params2track), params2track = [1 1]; end % = all
if iscolumn(y), y = y'; end
fs = sigproc_params.fs;

%% amplitude
% always compute this, as it's necessary to set threshold
y_ampl = get_sig_ampl(y,fs);
ampl_taxis = (0:(length(y_ampl)-1))/fs;

if sigproc_params.yes_smooth_amplitude  % smooth the amplitude
    y_ampl = smooth(yampl,0.1,'rloess');
end

if sigproc_params.yes_autosetampl  % find the ampl threshold
    sigproc_params.ampl_thresh4voicing = get_amplThresh(y_ampl,ampl_taxis);
end

sigmat.ampl = y_ampl;
sigmat.ampl_taxis = ampl_taxis;

%% pitch
if params2track(1)
    
    [y_pitch, pitch_taxis] = get_sig_pitch(y, fs, sigproc_params, [], [], []);
    
    % set subthreshold values to NaN
    ampl4pitch = interp1(ampl_taxis,y_ampl,pitch_taxis); %if pitch taxis and ampl taxis ever have different increments, then interpolate values such that the amplitude is in terms of pitchtaxis.
    y_pitch(ampl4pitch < sigproc_params.ampl_thresh4voicing) = NaN;
    
    sigmat.pitch = y_pitch;
    sigmat.pitch_taxis = pitch_taxis;
end

%% formants
if params2track(2)
    
    ms_framespec_gram = sigproc_params.ms_framespec_gram;
    ms_framespec_form = sigproc_params.ms_framespec_form;
    nfft = sigproc_params.nfft;
    nlpc = sigproc_params.nlpc;
    nformants = sigproc_params.nformants;
    preemph = sigproc_params.preemph;
    if isfield(sigproc_params,'ftrack_method')
        ftrack_method = sigproc_params.ftrack_method;
    else
        ftrack_method = 'praat';
    end
    
    %make spectrogram axdat
    [~,faxis_gram] = my_specgram(y,[],fs,ms_framespec_gram,nfft,preemph,0);
    
    %make ftrack axdat
    [ftrack,ftrack_msT,~] = get_formant_tracks(y,fs,faxis_gram,ms_framespec_form,nlpc,preemph,nformants,ftrack_method,0);
    
    % set subthreshold values to NaN
    ftrack_taxis = ftrack_msT/1000;
    ampl4form = interp1(ampl_taxis,y_ampl,ftrack_taxis);
    for iformant = 1:nformants
        ftrack(iformant,ampl4form < sigproc_params.ampl_thresh4voicing) = NaN;
    end
    
    sigmat.ftrack = ftrack;
    sigmat.ftrack_taxis = ftrack_taxis;
end
