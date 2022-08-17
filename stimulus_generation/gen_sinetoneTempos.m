function [tempoStims] = gen_sinetoneTempos(tempos, tBpmIsi, nBeats, tSavePlay, savedir, f0, amplitude, fs, blipDur, padDur, rampDur)
% Function that generates and either saves or plays completely regular tempos, with many parameters that you can control if
% you like. Primarily used for generating timitate stimuli. 
%
% Input arguments
% *** NOTE: ALL TIME/DURATION ARGUMENTS ARE GIVEN IN SECONDS (not milliseconds) 
% 
%       tempos              A vector of tempos. This can be in bpms or isis. Defaults to the range used in timitate. Note
%                           that isis are specified as center-to-center (or beginning to beginning), not end of impulse to
%                           beginning of impulse (i.e., it is not the duration of silence between impulses) 
% 
%       tBpmIsi             Toggle variable for if you have specified the tempos in 'bpm' or 'isi'. Defaults to bpm. 
% 
%       nBeats              The number of impulses you would like in the stimulus. Defaults to 5
% 
%       tSavePlay           Another toggle input if you want to 'save' or 'play' the resulting sound. Defaults to 'save'
% 
%       savedir             If you are saving, where you would like to save it. Defaults to timitate stimulus folder.
%                           Filenames are automatically generated from bpm and isi: e.g. 120bpm_500ms.wav. Decimals in bpm
%                           are replaced with x, isis are in ms and rounded to the nearest ms, e.g. 
%                           122.5 bpm -> 122x5bpm_490ms.wav
% 
%       f0                  The f0 of the impulse. There are essentially two options: an actual frequency, which will make a
%                           sinetone, or 'gamma', which will make an UNCUSTOMIZABLE gammatone click. (If you would like to
%                           customize the gammatone, gen_gammaMetronome will let you do this). Defaults to 200 Hz
% 
%       fs                  The sampling frequency of the resulting sound. Defaults to 24,000
% 
%       padDur              The duration of silence before the first click. Defaults to 0.25 
% 

% 
%       The remaining parameters only apply if you are using a sinetone rather than a gammatone
% 
%       amplitude           The amplitude of the sinetone. Defaults to 0.99
% 
%       blipDur             The duration of the sinetone. Defaults to 0.1
% 
%       rampDur             The sinetone is filtered through a Hanning window to avoid abrupt cutoffs/starts. This is the
%                           duration of the taper on either end of the sinetone. Defaults to 0.01. 
% 
% Output variables
% 
%       tempoStims          A cell array (to account for ragged rights) of the stimulus vectors in order of the tempos
%                           argument. 
% 
dbstop if error

%% Set defaults
if nargin < 1 || isempty(tempos), tempos = [90:6:180]; end
if nargin < 2 || isempty(tBpmIsi), tBpmIsi = 'bpm'; end
if nargin < 3 || isempty(nBeats), nBeats = 5; end
if nargin < 4 || isempty(tSavePlay), tSavePlay = 'save'; end
if nargin < 5 || isempty(savedir), savedir = '\\wcs-cifs\wc\smng\experiments\timitate\stimuli\sounds\tempos\staircase_wav_continuum'; end

if nargin < 6 || isempty(f0), f0 = 200; end
if nargin < 7 || isempty(amplitude), amplitude = 0.99; end
if nargin < 8 || isempty(fs), fs = 24000; end
if nargin < 9 || isempty(blipDur), blipDur = 0.1; end
if nargin < 10 || isempty(padDur), padDur = 0.25; end
if nargin < 11 || isempty(rampDur), rampDur = 0.01; end

nStimuli = length(tempos); 

%% Create the blip

if ischar(f0)
    % Checking for argument 'gamma'
    if strcmp(f0, 'gamma')
        blipDur = 0.015; 
        taxis = 0:(1/fs):blipDur; % 15 ms gammatone
        y = taxis.^(3) .* exp(-2*pi*150*taxis) .* cos(2*pi*1000*taxis); 
    else 
        warning('Unknown f0. Returning.')
        return; 
    end
else
    % Sinetone blip 
    taxis = 0:(1/fs):blipDur; 
    y = sin(2*pi*f0*taxis)*amplitude;
    
    % Apply Hanning window
    rampSamps = rampDur * fs; 
    window = hanning(2*rampSamps); 
    w1=window(1:ceil((length(window))/2))'; %use the first half of hanning function for onramp
    w2=window(ceil((length(window))/2)+1:end)'; %use second half of hanning function of off ramp

    w_on_y = [w1 ones(1,length(y)-length(w1))];
    w_off_y = [ones(1,length(y)-length(w2)) w2];

    y = y .* w_on_y .* w_off_y; 

    
end

% Zeros in front and behind the blip
blipPad = 0.005; 
zeroBlipPads = zeros(1, blipPad*fs); 
windowedPaddedBlip = [zeroBlipPads y zeroBlipPads]; 


%% String blips together
switch tBpmIsi
    case 'isi'
        bpms = isi2bpm(tempos, 0); 
        isis = tempos; 
    case 'bpm'
        bpms = tempos; 
        isis = bpm2isi(tempos, 0);   
end

% ISIs, accounting for 1. duration of blip and 2. duration of 0 padding
adjustedIsis = isis - (blipPad*2) - blipDur;             
padZeros = zeros(1, ceil(padDur*fs)); 

fprintf('Generating tempos... ')
for i = 1:length(adjustedIsis)
     adjustedIsi = adjustedIsis(i); 
     infoLine = tempos(i); 

    if ~mod(i, 20) || i == nStimuli
        fprintf('%.1f %s\n', infoLine, tBpmIsi); 
    else
        fprintf('%.1f %s ', infoLine, tBpmIsi); 
    end
    
    newSound = [];     
    isiZeros = zeros(1, ceil(adjustedIsi*fs)); 
    newSound = [padZeros repmat([windowedPaddedBlip, isiZeros], 1, nBeats-1) windowedPaddedBlip padZeros]; 
    maxMetronome = max(abs(newSound)); 
    newSound = newSound / maxMetronome; 

    % Information for saving 
    isiMs = round(isis(i)*1000); 
    bpm = bpms(i); 
    
    switch tSavePlay
        case 'save'
            switch tBpmIsi
                case 'bpm'
                    tempoSaveName = num2str(bpm); 
                    tempoSaveName = replace(tempoSaveName, '.', 'x'); % so 225.5 is 225x5 
                    audiowrite(fullfile(savedir, [tempoSaveName 'bpm.wav']), newSound, fs);   
                case 'isi'
                    isiSaveName = num2str(isiMs); % this is already rounded
                    audiowrite(fullfile(savedir, [isiSaveName 'ms.wav']), newSound, fs);   
            end
            
        case 'play'
            soundsc(newSound, fs);         
    end
    
    tempoStims{i} = newSound; 
    
end

fprintf('Done.\n')



end% EOF
