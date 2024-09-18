function check_audioLevels(what2check)
if nargin < 1
    what2check = 'a';
end

%% set up screens
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;

% close ctrl screen and enlarge experimenter's duplicated screen
close(h_fig(ctrl)); 
dup_position = [0 0.08 0.8 0.9]; %experimenter screen position
set(h_fig(3),'OuterPosition',dup_position);


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
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

AudapterIO('init', p);


%% run test
switch what2check
    case 'a'
        %% test headphone level
        Audapter('reset'); 
        Audapter('start'); 
        h_ready = draw_exptText(h_fig,-.4,.5,sprintf(['Testing mic and headphones.\n\n' ...
            'Speak into mic. You should hear noise and speech in headphones.\n\n' ...
            'Set SPL meter to:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\n' ...
            'Place SPL meter in headphones.\n' ...
            'Noise level should be ~60dB\n' ...
            'If not, adjust "pp headphones" knob on headphone amplifier.\n\n' ...
            'Press any key to stop.']),'Color','white','FontSize',35);
        pause
        Audapter('stop');

    case 'b'
        %% test headphone level
        Audapter('reset'); 
        Audapter('start'); 
        get_figinds_audapter;
        figure(h_fig(dup));
        h_ready_dup = text(-0.4, 0.5, sprintf(['Testing mic amplitude.\n\n' ...
            'Set SPL meter to:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\n' ...
            'Place SPL meter in headphones without foam cover.\n' ...
            'Noise level should be ~80db while pp says "head".\n' ...
            'If not, adjust microphone gain ("experiment mic").\n\n' ...
            'Press any key to stop.']), 'Color','white','FontSize',35);
        figure(h_fig(stim));
        h_ready_stim = text(0, 0.5, sprintf('Please say "head" with the vowel stretched out \n                until the noise goes away.'), 'Color','white','FontSize',35);
        pause
        Audapter('stop');
end
       
        %% clean up
        close all
end