%newwaveviewertemplate6;
%template for signal processing

% waveaxinfo

if size(y,1) ~= 1
    if size(y,2) ~= 1
        error('cannot currently handle signals that are matrices');
    else
        y = y'; % make y a row vector if it was a column vector
    end
end
fs = sigproc_params.fs;
name = plot_params.name;

waveaxinfo.params.fs = fs;
waveaxinfo.yes_create_hplayer = sigproc_params.yes_create_hplayer;

if sigproc_params.yes_create_hplayer
    waveaxinfo.params.player_started = 0;
    waveaxinfo.params.start_player_t = 0;
    waveaxinfo.params.stop_player_t = 0;
    waveaxinfo.params.current_player_t = 0;
    waveaxinfo.params.inc_player_t = 0.01;
    h_player = audioplayer(0.5*y/max(abs(y)),fs); % the scaling of y is a bit of a hack to make audioplayer play like soundsc
    waveaxinfo.params.h_player = h_player;
    waveaxinfo.params.isamps2play_total = get(h_player,'TotalSamples');
%     set(h_player,'StartFcn',@player_start);
%     set(h_player,'StopFcn',@player_stop);
%     set(h_player,'TimerFcn',@player_runfunc);
%     set(h_player,'TimerPeriod',waveaxinfo.params.inc_player_t);
end

waveaxinfo.i = plot_params.iordersubplots(1,1);
waveaxinfo.type = 'wave';
waveaxinfo.name = name;
waveaxinfo.dat{1} = y;
waveaxinfo.datlims = size(waveaxinfo.dat{1});
waveaxinfo.taxis = (0:(length(y)-1))/fs;
waveaxinfo.faxis = [];

waveaxinfo.tmin = waveaxinfo.taxis(1);
waveaxinfo.tmax = waveaxinfo.taxis(end);
waveaxinfo.trange = waveaxinfo.tmax - waveaxinfo.tmin;

waveaxinfo.axfract = plot_params.axfracts;
waveaxinfo.yes_tmarker_play = 1;
waveaxinfo.yes_add_user_events = 1;
waveaxinfo.spec_marker_name.name = ' %.3f s ';
waveaxinfo.spec_marker_name.vert_align = 'top';
waveaxinfo.spec_marker_name.bgrect.color = 'same';

%%
% amplaxinfo

yampl = get_sig_ampl(y,fs);
len_yampl = length(yampl);
ampltaxis = (0:(len_yampl-1))/fs;
yes_smooth_amplitude = sigproc_params.yes_smooth_amplitude;
yes_autosetampl = sigproc_params.yes_autosetampl;

if yes_smooth_amplitude
    yy1 = smooth(yampl,0.1,'rloess');
    ampl2use = yy1;
else
    ampl2use = yampl;
end

if yes_autosetampl
    ampltaxis = ampltaxis';
    indices2regressi = sigproc_params.indices2regress; %every 0.1s  do for 0.04s
    indices2regress = indices2regressi;
    beginregress = 1;
    
    numregressions = floor(length(ampl2use)/indices2regressi);
    cumyhat = [];
    cumslopes = [];
    newstats{1,numregressions} = [];
    thistime = zeros(1,numregressions);
    
    for loop = 1:numregressions
        newstats{1,loop} = regstats(ampl2use(beginregress:indices2regress,1),ampltaxis(beginregress:indices2regress,1));
        beginregress = beginregress + indices2regressi;
        indices2regress = indices2regress + indices2regressi;
        
        thisyhat = newstats{1,loop}.yhat;
        thisslope = (thisyhat(end) - thisyhat(1))/ampltaxis(indices2regressi);
        thistime(1,loop) = ampltaxis(loop*indices2regressi);
        cumyhat = [cumyhat thisyhat'];
        cumslopes = [cumslopes thisslope];
    end
    
    diffslopes = diff(cumslopes);
    
    firstchangefromzero = find(abs(cumslopes) > 0.5,1,'first') - 1;
    timechangefromzero = thistime(1,firstchangefromzero);
    indicechangefromzero = find(ampltaxis == timechangefromzero,1);
    yvalforamplthresh = ampl2use(indicechangefromzero); %use smoothed amplitude for this
    ampl_thresh4voicing = yvalforamplthresh;
    ampl2use = ampl2use';
    ampltaxis = ampltaxis';
    sigproc_params.ampl_thresh4voicing = ampl_thresh4voicing;
else
    ampl_thresh4voicing = sigproc_params.ampl_thresh4voicing;
end

amplaxinfo.params.fs = fs;
amplaxinfo.i = plot_params.iordersubplots(1,2);
amplaxinfo.type = 'ampl';
amplaxinfo.name = name;
amplaxinfo.rawyampl = yampl;
amplaxinfo.dat{1} = ampl2use;
amplaxinfo.datlims = size(amplaxinfo.dat{1});
amplaxinfo.taxis = ampltaxis;
amplaxinfo.faxis = [];

amplaxinfo.tmin = amplaxinfo.taxis(1);
amplaxinfo.tmax = amplaxinfo.taxis(end);
amplaxinfo.trange = amplaxinfo.tmax - amplaxinfo.tmin;

amplaxinfo.axfract = plot_params.axfracts;
amplaxinfo.yes_tmarker_play = 0;
amplaxinfo.yes_add_user_events = 1;
amplaxinfo.spec_marker_name.name = ' %.2f ';
amplaxinfo.spec_marker_name.vert_align = 'top';
amplaxinfo.spec_marker_name.idatsources = [1];
amplaxinfo.spec_marker_name.bgrect.color = 'same';

%%
%pitchaxinfo

pitchlimits = sigproc_params.pitchlimits;
[ypitch,window_size,frame_step,nframes] = get_sig_pitch(y,fs,pitchlimits);
pitchaxinfo.rawypitch = ypitch;
len_ypitch = length(ypitch);
pitch_taxis = (0:(len_ypitch-1))/fs;
ampl4pitch = interp1(amplaxinfo.taxis,amplaxinfo.dat{1},pitch_taxis); %if pitch taxis and ampl taxis ever have different increments, then interpolate values such that the amplitude is in terms of pitchtaxis.
ypitch(ampl4pitch < ampl_thresh4voicing) = NaN;

pitchaxinfo.params.fs = fs;
pitchaxinfo.params.pitchlimits = pitchlimits;

pitchaxinfo.i = plot_params.iordersubplots(1,3);
pitchaxinfo.type = 'pitch';
pitchaxinfo.name = name;
pitchaxinfo.dat{1} = ypitch;
pitchaxinfo.datlims = size(pitchaxinfo.dat{1});
pitchaxinfo.taxis = pitch_taxis;
pitchaxinfo.faxis = [];

pitchaxinfo.tmin = pitchaxinfo.taxis(1);
pitchaxinfo.tmax = pitchaxinfo.taxis(end);
pitchaxinfo.trange = pitchaxinfo.tmax - pitchaxinfo.tmin;

pitchaxinfo.axfract = plot_params.axfracts;
pitchaxinfo.yes_tmarker_play = 0;
pitchaxinfo.yes_add_user_events = 1;
pitchaxinfo.spec_marker_name.name = ' %.0f Hz ';
pitchaxinfo.spec_marker_name.vert_align = 'top';
pitchaxinfo.spec_marker_name.idatsources = [1];
pitchaxinfo.spec_marker_name.bgrect.color = 'same';

%%
% gramaxinfo

ms_framespec_gram = sigproc_params.ms_framespec_gram;
ms_framespec_form = sigproc_params.ms_framespec_form;

nfft = sigproc_params.nfft;
nlpc = sigproc_params.nlpc;
nformants = sigproc_params.nformants;
preemph = sigproc_params.preemph;

%make spectrogram axdat
[absS,F,msT,window_size,frame_size] = my_specgram(y,[],fs,ms_framespec_gram,nfft,preemph,0);
[nchans,nframes_gram] = size(absS);
faxis_gram = F;
frame_taxis_gram = msT/1000;

%make ftrack axdat
[ftrack,ftrack_msT,lpc_coeffs] = get_formant_tracks(y,fs,faxis_gram,ms_framespec_form,nlpc,preemph,nformants,'mine2',0);
gramaxinfo.rawftrack = ftrack;
gramaxinfo.rawlpc_coeffs = lpc_coeffs;
[nforms,nframes_form] = size(ftrack);
frame_taxis_form = ftrack_msT/1000;
ampl4form = interp1(amplaxinfo.taxis,amplaxinfo.dat{1},frame_taxis_form);
for iformant = 1:nformants
    ftrack(iformant,ampl4form < ampl_thresh4voicing) = NaN;
end
for i_lpc_coeff = 1:nlpc
    lpc_coeffs(i_lpc_coeff,ampl4form < ampl_thresh4voicing) = NaN;
end

gramaxinfo.params.fs = fs;
gramaxinfo.params.ms_framespec_gram = ms_framespec_gram;
gramaxinfo.params.nfft = nfft;
gramaxinfo.params.preemph = preemph;

gramaxinfo.params.ms_framespec_form = ms_framespec_form;
gramaxinfo.params.nlpc = nlpc;
gramaxinfo.params.nformants = nformants;
gramaxinfo.params.lpc_coeffs = lpc_coeffs;

gramaxinfo.i = plot_params.iordersubplots(1,4);
gramaxinfo.type = 'gram';
gramaxinfo.name = name;
gramaxinfo.dat{1} = absS;
gramaxinfo.dat{2} = ftrack;
gramaxinfo.datlims = size(gramaxinfo.dat{1});
gramaxinfo.faxis = faxis_gram;
gramaxinfo.taxis = frame_taxis_form;

gramaxinfo.taxis_gram = frame_taxis_gram;
gramaxinfo.taxis_form = frame_taxis_form;

gramaxinfo.tmax = gramaxinfo.taxis_gram(end);
gramaxinfo.tmin = gramaxinfo.taxis_gram(1);
gramaxinfo.trange = gramaxinfo.tmax - gramaxinfo.tmin;

gramaxinfo.axfract = plot_params.axfracts;
gramaxinfo.yes_tmarker_play = 0;
gramaxinfo.yes_add_user_events = 1;

for iformant = 1:nformants
    gramaxinfo.spec_marker_name(iformant).name = ' %.0f Hz ';
    gramaxinfo.spec_marker_name(iformant).vert_align = 'top';
    gramaxinfo.spec_marker_name(iformant).idatsources = [2];
    gramaxinfo.spec_marker_name(iformant).iidatsource4ypos = 1;
    gramaxinfo.spec_marker_name(iformant).idatrows = iformant;
    gramaxinfo.spec_marker_name(iformant).bgrect.color = 'same';
end
wave_viewer_logshim = sigproc_params.wave_viewer_logshim;
gramaxinfo.absS2plot = 20*log10(gramaxinfo.dat{1}+wave_viewer_logshim);

%%
%sliceaxinfo

t_slice = gramaxinfo.tmin + gramaxinfo.trange/2;

faxis = gramaxinfo.faxis;

%make_gram_slice_axdat
iframe_gram = dsearchn(gramaxinfo.taxis_gram',t_slice);
gram_frame_slice = gramaxinfo.dat{1}(:,iframe_gram)';

iframe_form = dsearchn(faxis,t_slice);
form_frame_formants = gramaxinfo.dat{2}(:,iframe_form);
form_frame_lpc_slice = get_lpc_magspec(lpc_coeffs(:,iframe_form),faxis,fs)';

sliceaxinfo.params.iframe_gram = iframe_gram;
sliceaxinfo.params.iframe_form = iframe_form;
sliceaxinfo.params.formants = form_frame_formants;

sliceaxinfo.i = plot_params.iordersubplots(1,5);
sliceaxinfo.type = 'slice';
sliceaxinfo.name = name;
sliceaxinfo.dat{1} = gram_frame_slice;
sliceaxinfo.dat{2} = form_frame_lpc_slice;
sliceaxinfo.datlims = size(sliceaxinfo.dat{1});

sliceaxinfo.taxis = faxis_gram';
sliceaxinfo.faxis = [];

sliceaxinfo.tmax = sliceaxinfo.taxis(end);
sliceaxinfo.tmin = sliceaxinfo.taxis(1);
sliceaxinfo.trange = sliceaxinfo.tmax - sliceaxinfo.tmin;

sliceaxinfo.axfract = plot_params.axfracts;
sliceaxinfo.yes_tmarker_play = 0;
sliceaxinfo.yes_add_user_events = 0;
sliceaxinfo.spec_marker_name.name = ' %.0f Hz ';
sliceaxinfo.spec_marker_name.vert_align = 'top';
sliceaxinfo.spec_marker_name.bgrect.color = 'same';

disp('Signal Processing and Definitions Complete');