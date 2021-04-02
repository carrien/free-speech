function check_maskLevels(fb, fbGain)
%check masking levels for experiement
%fb = feedback mode
%fbGain = manual input of noise mask level (if different than standard)

if nargin < 1 || isempty(fb), fb = 2; end
%% set up screens
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;

%% initialize Audapter 
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);
Audapter('ost', '', 0);     % nullify online status tracking/
Audapter('pcf', '', 0);     % pert config files (use pert field instead)

% set audapter params
p = getAudapterDefaultParams('female'); % get default params
% overwrite selected params with experiment-specific values:
p.bShift = 1;
p.bRatioShift = 0;
p.bMelShift = 1;

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = fb;
if nargin < 2 || isempty(fbGain)
    p.fb2Gain = 0.16; %should be ~77
else
    gain = sprintf('fb%dGain', fb);
    p.(gain) = fbGain;
end

AudapterIO('init', p);

%% run test      
%% test headphone level
Audapter('reset'); 
Audapter('start'); 
h_ready = draw_exptText(h_fig,-.3,.5,sprintf('Level testing has started.\n\nBe sure headphones are plugged into output 1 of headphone amplifier.\n\nMake sure audiometer settings are:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\nPlace SPL meter in headphones without foam cover.\nNoise level should be ~78dB.\nIf levels are off, adjust headphone output knob on headphone amplifier.\n\nPress any key to stop once levels are confirmed.'),'Color','white','FontSize',35);
pause
Audapter('stop');
delete_exptText(h_fig,h_ready)      
%% clean up
close all
end