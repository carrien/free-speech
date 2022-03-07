function check_audioLevels(what2check)
if nargin < 1
        what2check = questdlg({'do you want to check'; ...
        '(a): that the mic and headphones are working, then check background noise levels (before participant arrives)';...
        '(b): the microphone level with the participant'},'What do you want to check?','(a)','(b)','(a)');
end

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
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

AudapterIO('init', p);


%% run test
switch what2check
    case '(a)'
        %% test mic and headphones
        % give instructions and wait for keypress
        Audapter('reset'); 
        Audapter('start'); 
        h_ready = draw_exptText(h_fig,-.3,.5,{'Testing mic and headphones.';'Make sure you can hear your voice played back';'Press space to end test'},'Color','white','FontSize',35);
        pause
        Audapter('stop');
        delete_exptText(h_fig,h_ready)
        
        %% test headphone level
        Audapter('reset'); 
        Audapter('start'); 
        h_ready = draw_exptText(h_fig,-.3,.5,sprintf('Level testing has started.\n\nBe sure headphones are plugged into output 1 of headphone amplifier.\n\nMake sure audiometer settings are:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\nPlace SPL meter in headphones without foam cover.\nNoise level should be ~60dB.\nIf levels are off, adjust headphone output knob on headphone amplifier.\n\nPress any key to stop once levels are confirmed.'),'Color','white','FontSize',35);
        pause
        Audapter('stop');
        delete_exptText(h_fig,h_ready)

    case '(b)'
        %% test headphone level
        Audapter('reset'); 
        Audapter('start'); 
        get_figinds_audapter;
        figure(h_fig(dup));
        h_ready_dup = text(-0.3, 0.5, sprintf('Level testing has started.\n\nBe sure headphones are plugged into output 1 of headphone amplifier.\n\nMake sure audiometer settings are:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\nPlace SPL meter in headphones without foam cover.\nHave the participant sustain the word "head" at a comfortable voume.\nNoise level should be ~80db.\nAdjust the microphone gain (black knob) if this is too low or too high.\n\nPress any key to stop once levels are confirmed.'),'Color','white','FontSize',35);
        figure(h_fig(stim));
        h_ready_stim = text(0, 0.5, sprintf('Please say "head" with the vowel stretched out \n                until the noise goes away.'), 'Color','white','FontSize',35);
        pause
        Audapter('stop');
        delete_exptText(h_fig,h_ready_dup)
        delete_exptText(h_fig,h_ready_stim)
end
       
        %% clean up
        close all
end