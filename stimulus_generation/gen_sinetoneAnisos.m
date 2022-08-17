function [] = gen_sinetoneAnisos(savedir, tempo, anisos, nBeats, f0, amplitude, fs, blipDur, padDur, rampDur)
% Script to generate base tempos with anisochronies in the last beat, both longer than standard and shorter than standard
% 
% last minute task change for relative timing task 
% 
% Based on teki et al 2011
% 
% INitiated RPK 2021-11-08
% 

dbstop if error

%% Defaults
if nargin < 1 || isempty(savedir), savedir = '\\wcs-cifs\wc\smng\experiments\timitate\stimuli\sounds\anisochronies\staircase_wav_continuum'; end
if nargin < 2 || isempty(tempo), tempo = 120; end                           % Standard tempo for other blips
if nargin < 3 || isempty(anisos), anisos = [0.005:0.005:0.100]; end         % Jitter mags for last interval in seconds
if nargin < 4 || isempty(nBeats), nBeats = 4; end                           % Number of isochronous beat (there will be total nBeats + 1)

if nargin < 5 || isempty(f0), f0 = 200; end                                 % F0 of blip
if nargin < 6 || isempty(amplitude), amplitude = 0.99; end                  % Amplitude of blip
if nargin < 7 || isempty(fs), fs = 24000; end                               % Sampling rate of sound
if nargin < 8 || isempty(blipDur), blipDur = 0.05; end                      % Duration of blip
if nargin < 9 || isempty(padDur), padDur = 0.25; end                        % 0 padding on ends of full soundfile
if nargin < 10 || isempty(rampDur), rampDur = 0.01; end                     % Ramp duration for blip 
nStimuli = length(anisos); 

%% Create pure tone blip
taxis = 0:(1/fs):blipDur;
y = sin(2*pi*f0*taxis)*amplitude;

% Apply Hanning window
rampSamps = rampDur * fs; 
window = hanning(2*rampSamps); 
w1=window(1:ceil((length(window))/2))'; %use the first half of hanning function for onramp
w2=window(ceil((length(window))/2)+1:end)'; %use second half of hanning function of off ramp

w_on_y = [w1 ones(1,length(y)-length(w1))];
w_off_y = [ones(1,length(y)-length(w2)) w2];

windowedBlip = y .* w_on_y .* w_off_y; 

% Zeros
blipPad = 0.01; 
zeroBlipPads = zeros(1, blipPad*fs); 
% padTaxis = 0:(1/fs):(blipDur+(padDur*2));

% Save the single blip
windowedPaddedBlip = [zeroBlipPads windowedBlip zeroBlipPads]; 
audiowrite(fullfile(savedir, 'singleBlip.wav'), windowedPaddedBlip, fs); 

%% String blips together
isi = bpm2isi(tempo, 0); 
isiMs = bpm2isi(tempo, 1); 
adjustedIsi = isi - (blipPad*2) - blipDur;             % ISIs, accounting for 1. duration of blip and 2. duration of 0 padding
padZeros = zeros(1, ceil(padDur*fs)); 

fprintf('Generating base tempo... ')
baseTempo = []; 
isiZeros = zeros(1, ceil(adjustedIsi*fs)); 
% Make the first nBeats beats
baseTempo = [padZeros repmat([windowedPaddedBlip, isiZeros], 1, nBeats-1) windowedPaddedBlip]; 
tempoSaveName = num2str(tempo); 
tempoSaveName = replace(tempoSaveName, '.', 'x'); % so 225.5 is 225x5 

fprintf('Generating anisochronies... ')
for i = 1:length(anisos)
    aniso = anisos(i); 
    if ~mod(i, 20) || i == nStimuli
        fprintf('%.1f bpm\n', aniso*1000); 
    else
        fprintf('%.1f ', aniso*1000); 
    end
    anisoSaveName = num2str(aniso*1000); 
    anisoSaveName = replace(anisoSaveName, '.', 'x'); 
    
    % Get durations of last ISI (plus and minus the standard isi) 
    anisoPlus = adjustedIsi + aniso; 
    anisoMinus = adjustedIsi - aniso; 
    
    % Make the zeros for each
    anisoPlus_zeros = zeros(1, ceil(anisoPlus*fs)); 
    anisoMinus_zeros = zeros(1, ceil(anisoMinus*fs)); 
    
    anisoPlus_sound = [baseTempo anisoPlus_zeros windowedPaddedBlip padZeros]; 
    audiowrite(fullfile(savedir, [tempoSaveName 'bpm_' anisoSaveName 'ms_plus.wav']), anisoPlus_sound, fs);  
    
    anisoMinus_sound = [baseTempo anisoMinus_zeros windowedPaddedBlip padZeros]; 
    audiowrite(fullfile(savedir, [tempoSaveName 'bpm_' anisoSaveName 'ms_minus.wav']), anisoMinus_sound, fs);  
 
end



fprintf('Done.\n')



end% EOF
