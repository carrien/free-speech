function [sinetones] = gen_sinetoneDurs(savedir, durs, f0, amplitude, fs, padDur, rampDur, bSave)
% Function to quickly generate sine tones for timitate (event timing). Uses a hanning window
% 
% 1. savedir: directory to save new sound files into. Defaults to the stimulus directory on the server
% 2. durs: a vector of durations you want to create, in MS (not seconds). Defaults to 150:10:350
% 3. f0: f0 of the sinetone. Defaults to 200
% 4. amplitude: amplitude of the sinetone. Defaults to 0.99. 
% 5. fs: sampling rate. Defaults to 24000
% 6. padDur: duration of the silences before and after the sine tone. Defaults to 250 ms
% 7. rampDur: duration of the hanning window ramp. Defaults to 10 ms

dbstop if error

%% Default args
if nargin < 1 || isempty(savedir), savedir = '\\wcs-cifs\wc\smng\experiments\timitate\stimuli\sounds\tones\staircase_wav_continuum'; end
if nargin < 2 || isempty(durs), durs = [150:10:350]; end

if nargin < 3 || isempty(f0), f0 = 200; end
if nargin < 4 || isempty(amplitude), amplitude = 0.99; end
if nargin < 5 || isempty(fs), fs = 24000; end
if nargin < 6 || isempty(padDur), padDur = 0.25; end
if nargin < 7 || isempty(rampDur), rampDur = 0.01; end
if nargin < 8 || isempty(bSave), bSave = 0; end
nStimuli = length(durs); 

%% Create stimuli
fprintf('Generating stimuli... '); 
for d = 1:nStimuli    
    dur = durs(d)/1000;
    durMs = durs(d); 
    if ~mod(d, 20) || d == nStimuli
        fprintf('%.1f ms\n', durMs); 
    else
        fprintf('%.1f ', durMs); 
    end
    toneTaxis = 0:(1/fs):dur;
    toney = sin(2*pi*f0*toneTaxis)*amplitude; 
 
    % Apply Hanning window
    rampSamps = rampDur * fs; 
    window = hanning(2*rampSamps); 
    w1=window(1:ceil((length(window))/2))'; %use the first half of hanning function for onramp
    w2=window(ceil((length(window))/2)+1:end)'; %use second half of hanning function of off ramp

    w_on_y = [w1 ones(1,length(toney)-length(w1))];
    w_off_y = [ones(1,length(toney)-length(w2)) w2];

    windowedBlip = toney .* w_on_y .* w_off_y; 

    % Zeros
    zeroPads = zeros(1, padDur*fs); 
    padTaxis = 0:(1/fs):(dur+(padDur*2));
    
    % Get full tone, windowed + 0 padding
    newSound = [zeroPads windowedBlip zeroPads]; 
    sinetones{d} = newSound; 
    
    % Save
    if bSave
        if round(durMs) ~= durMs 
            durSaveName = sprintf('%.1f',durMs); 
            durSaveName = replace(durSaveName, '.', 'x'); % so 225.5 is 225x5 
        else 
            durSaveName = num2str(durMs); 
        end
        audiowrite(fullfile(savedir, [durSaveName 'ms.wav']), newSound, fs); 
    end
    
    
    
end

fprintf('Done.\n')


end% EOF
