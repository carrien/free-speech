function run_passageReading()
% Run Audapter in feedback mode 3 (hear speech and noise) while displaying
%   a black screen. Before and after running Audapter, display a "Time for a
%   break" message. 
%
% Intended to be used for experiments like cerebAAF and adaptRetest, where
%   the participant is reading the "rainbow" passage or something similar
%   and hearing their own speech with unaltered feedback.
%
% The speaker's speech is not saved in any way.

% 2022-?? Ben Parrell wrote initial code
% 2022-10 Chris Naber split out to own function and updated.


% Set up displays
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;

% set text
color2display = [1 1 1]; %white
stimtxtsize = 50;

fprintf('Starting passage-reading section.\nGive instructions, then press ENTER to START Audapter.\n');
h_text = draw_exptText(h_fig,.5,.5,'Please wait.', 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
input('', 's');

% clear screen
delete_exptText(h_fig,h_text)
clear h_text

%set up audapter
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);

% nullify online status tracking/pert config files (use pert field instead)   
Audapter('ost', '', 0);         
Audapter('pcf', '', 0);

% set audapter params
p = getAudapterDefaultParams('female'); % get default params. Gender doesn't matter b/c not perturbing

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

% Initialize Audapter 
AudapterIO('init', p);
Audapter('reset'); %reset Audapter
Audapter('start'); %start trial
fprintf('Press ENTER to STOP Audapter when finished reading.\n');
input('', 's');
Audapter('stop'); %stop Audapter

fprintf('Press any key to leave passage-reading section.\n');
h_text = draw_exptText(h_fig,.5,.5,'Please wait.', 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
pause
fprintf('Leaving passage-reading section.\n'); 
close(h_fig); 

end %EOF
