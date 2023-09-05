function [] = pause_trial(h_fig,params)

get_figinds_audapter;

% text params
if nargin < 2 || isempty(params)
    params = struct;
end

% if changing defaults, consider also changing free-speech\experiment_helpers\set_exptDefaults.m
params = set_missingField(params, 'pausetxt', 'Experiment paused. Please wait.', 1);
params = set_missingField(params, 'conttxt', 'Experiment will now continue.', 1);
pausetxt = params.pausetxt;
conttxt = params.conttxt;

txtparams.Color = 'white';
txtparams.FontSize = 60;
txtparams.HorizontalAlignment = 'center';
txtparams.Units = 'normalized';

% display pause text and wait for keypress
figure(h_fig(stim))
h1_sub = subplot(1,1,1);
set(h1_sub, 'color', 'black')
axis off
h_text = draw_exptText(h_fig, .5, .5, pausetxt, txtparams); % display pause text
pause

% resume after keypress
try
    set(h_fig(stim),'CurrentCharacter','@')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','@')
    set(h_fig(dup),'CurrentCharacter','@')
catch
end

delete_exptText(h_fig,h_text) % clear pause text
clear h_text
h_text = draw_exptText(h_fig, .5, .5, conttxt, txtparams); % display continue text
pause(1)
delete_exptText(h_fig,h_text)             % clear continue text
pause(1)

end %EOF
