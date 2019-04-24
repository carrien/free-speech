function [ ] = run_audapterDemo()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

expt.gender = get_gender;

audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);
Audapter('ost', '', 0);     % nullify online status tracking/
Audapter('pcf', '', 0);     % pert config files (use pert field instead)

% set audapter params
p = getAudapterDefaultParams(expt.gender); % get default params
% overwrite selected params with experiment-specific values:
p.bShift = 1;
p.bRatioShift = 0;
p.bMelShift = 1;

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

%% initialize Audapter
AudapterIO('init', p);

Audapter('reset'); %reset Audapter
Audapter('start');

fprintf('Press any key to begin shifting F1 up.\n');
pause;

p.pertAmp = 200*ones(1, 257);
p.pertPhi = zeros(1, 257);
Audapter('setParam','pertAmp',p.pertAmp)
Audapter('setParam','pertPhi',p.pertPhi)

fprintf('Press any key to begin shifting F1 down.\n')
pause;

p.pertPhi = pi * ones(1, 257);
Audapter('setParam','pertAmp',p.pertAmp)
Audapter('setParam','pertPhi',p.pertPhi)

fprintf('Press any key to return to normal feedback.\n')
pause;

p.pertAmp = zeros(1, 257);
Audapter('setParam','pertAmp',p.pertAmp)
Audapter('setParam','pertPhi',p.pertPhi)

fprintf('Press any key to end the demo.\n')
pause;

Audapter('stop');

end

