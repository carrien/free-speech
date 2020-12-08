function audapter_testcases()
% This function goes through some standard Audapter test cases to make sure
% Audapter can run properly on your computer. It is intended to be used
% with the "flex" version of Audapter, which does the following things:

%{
To wit, this function tests:
1. "low frequency". 48kHz hardware sampling rate, 3x downfactor; thus
  16kHz.
2. "high frequency". A different Chebyshev Type II filter was
  developed for frequencies higher than 16kHz. 48kHz hardware SR, 2x
  downfactor; thus 24kHz.
3. "no dropouts". Previous versions of Audapter would stop perturbing the
  output signal based on formant perturbation settings after the first
  instance of a vowel was detected in a trial. The "flex" version can
  perform formant perturbations even with interruptions.
4. "1D". Formant perturbation of F1 and F2 varies only based on F2.
5. "2D". Formant perturbation of F1 and F2 varies based on F1 and F2.
%}    
%
% CWN 11-2020

%% Set up params that are consistent between configurations

clear Audapter % Allows loading of new mex in same MATLAB session, if needed

fprintf('----------See text printout for test case results---------\n\n')

if isempty(which('Audapter'))
    fprintf('No file named ''Audapter'' found. Make sure it''s on your search path. \n')
    fprintf('  Test with `which Audapter`');
else
    fprintf('The following Audapter file(s) were found; the first in the list will be used.\n')
    which Audapter -all
end

%Matlab Variables
audioInterfaceName = 'Focusrite USB';
sRate = 48000; %(before downsampling)
downFact = 3;
frameLen = 96;
gender = 'male';

%Use Matlab Variables to set Audapter Params
Audapter('deviceName', audioInterfaceName);
%Audapter('setParam', 'downFact', downFact, 0);          
%Audapter('setParam', 'sRate', sRate / downFact, 0);     
Audapter('setParam', 'frameLen', frameLen / downFact, 0);

fprintf('\nAudapter mex file accessed successfully. \n\n');


% These test cases use a pre-recorded audio sample
filename = fullfile(get_gitPath, 'free-speech', 'experiment_helpers', 'audapter_testcases_audio.mat');
load(filename, 'signalIn'); % this file's native sampling rate is 48000

% convert audio file to "frame"-length chunks for use in Audapter
downFact_lowFs = 3;
signalIn_lowFs_cell = makecell(signalIn, 32 * downFact_lowFs);

downFact_highFs = 2;
signalIn_highFs_cell = makecell(signalIn, 32 * downFact_highFs);

%% Example of Audapter running properly with a 1D + lowFs configuration

fprintf('Now testing 1D (F2 only considered for formant shifts) and low Fs (16kHz post-downsampling).\n')

Audapter('ost', '', 0);
Audapter('pcf', '', 0);

p1 = getAudapterDefaultParams(gender);

% shifts
fieldDim = 257;
p1.F1Min = 0;
p1.F1Max = 5000;
p1.F2Min = 0;
p1.F2Max = 5000;
p1.pertF2 = linspace(0, 5000, fieldDim);
p1.pertAmp = 0.3 * ones(1, fieldDim);
p1.pertPhi = 0.75 * pi * ones(1, fieldDim);
p1.bShift = 1;
p1.bShift2D = 0; %set to 0 to use 1D

p1.fb = 1;  %feedback mode 1, "voice only"


AudapterIO('init', p1);

Audapter('setParam', 'downFact', downFact_lowFs, 0);          
Audapter('setParam', 'sRate', sRate / downFact_lowFs, 0);     

Audapter('reset');
for n = 1 : length(signalIn_lowFs_cell)
    Audapter('runFrame', signalIn_lowFs_cell{n});
end

data_1d = AudapterIO('getData');

% TODO is any of this needed?
bGoodDataFile = ~isempty(data_1d); % make sure 'getData' returned something
if bGoodDataFile
    fprintf('Audapter returned data (good). See further instructions for examining graphs\n');
else
    error('Audapter didn''t return any data during 1D + lowFs.\n')
end
%bGoodFormants = any(find(data_1d.sfmts ~= 0)); % make sure formant tracking worked on signalOut

% plot the output
show_spectrogram(data_1d.signalIn, data_1d.params.sr, 'noFig');
title('1D and lowFs');
tAxis = 0 : p1.frameLen : p1.frameLen * (size(data_1d.fmts, 1) - 1);
plot(tAxis/data_1d.params.sr,data_1d.fmts(:, 1 : 2), 'c','LineWidth',2);
plot(tAxis/data_1d.params.sr,data_1d.sfmts(:, 1 : 2), 'm','LineWidth',1);

%% Example of Audapter running properly with a 2D + highFs configuration

fprintf('\nNow testing 2D (F2+F1 considered for formant shifts) and high Fs (24kHz post-downsampling).\n')

Audapter('ost', '', 0);     % nullify online status tracking
Audapter('pcf', '', 0);

p2 = getAudapterDefaultParams(gender); 

% define basic male vowel space, then calculate 2D pert field
fmt.iy = [295 2194]; fmt.ae = [572 1596]; fmt.uw = [228 1313]; fmt.aa = [636 1377];
pertField = calc_pertField('in', fmt, 1, 0);

% shifts
%fieldDim = 257;
p2.F1Min = pertField.F1Min;
p2.F1Max = pertField.F1Max;
p2.F2Min = pertField.F2Min;
p2.F2Max = pertField.F2Max;
%p2.f1Min = 0;
%p2.f1Max = 5000;
%p2.f2Min = 0;
%p2.f2Max = 5000;
p2.pertAmp2D = pertField.pertAmp * 0.25;
p2.pertPhi2D = pertField.pertPhi;
p2.bShift = 1;
p2.bMelShift = 1;
p2.bRatioShift = 0;
p2.bShift2D = 1;    % set to 1 to use 2D

p2.fb = 1;  %feedback mode 1, "voice only"


AudapterIO('init', p2);

Audapter('setParam', 'downFact', downFact_highFs, 0);          
Audapter('setParam', 'sRate', sRate / downFact_highFs, 0);     

Audapter('reset');

for n = 1 : length(signalIn_highFs_cell)
    Audapter('runFrame', signalIn_highFs_cell{n});
end

data_2d = AudapterIO('getData');

bGoodDataFile = ~isempty(data_2d); % make sure 'getData' returned something
if bGoodDataFile
    fprintf('Audapter returned data for 2D + highFs (good). See further instructions for examining graphs.\n');
else
    error('Audapter didn''t return any data during 1D + lowFs.\n')
end

fprintf('\n')

% plot the output
fig_2 = figure;
movegui(fig_2, [400, 800]);
show_spectrogram(data_2d.signalIn, data_2d.params.sr, 'noFig');
title('2D and highFs');
tAxis = 0 : p2.frameLen : p2.frameLen * (size(data_2d.fmts, 1) - 1);
plot(tAxis/data_2d.params.sr,data_2d.fmts(:, 1 : 2), 'c','LineWidth',2);
plot(tAxis/data_2d.params.sr,data_2d.sfmts(:, 1 : 2), 'm','LineWidth',1);

msg_graphs = ['HOW TO EVALUATE PLOTS: each plot should have a cyan and magenta line. \n' ...
    '  To confirm there''s no "dropouts," the magenta line should go to zero around... \n' ...
    '  the 0.7 and 1 second mark, then return to a non-zero value.\n'];
fprintf(msg_graphs);

% Play signalOut
play_audio(data_1d.signalOut, sRate/downFact_lowFs);
play_audio(data_2d.signalOut, sRate/downFact_highFs)

msg_audio = ['\nHOW TO EVALUATE AUDIO: You should hear two instances of "popping popcorn."' ...
    ' Both should be slightly shifted, since the audio is from signalOut.\n\n'];
fprintf(msg_audio);

%wrap-up
fprintf('\nIf all that looks good, you have passed the all the test cases!\n')
fprintf('For further testing (e.g., live audio), try running experiments in test mode.\n\n');

end