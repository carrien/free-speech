function [] = pause_trial(h_fig)

get_figinds_audapter;

% text params
pausetxt = 'Paused. Press the space bar to continue.';
conttxt = 'We will now continue.';
txtparams.Color = 'white';
txtparams.FontSize = 60;
txtparams.HorizontalAlignment = 'center';

% display pause text and wait for keypress
figure(h_fig(stim))
h1_sub = subplot(1,1,1);
set(h1_sub, 'color', 'black')
axis off
h_text = text(.5,.5,pausetxt,txtparams);
CloneFig(h_fig(stim),h_fig(dup))
pause

% resume after keypress
set(h_fig(stim),'CurrentCharacter','@')  % reset keypress
set(h_fig(ctrl),'CurrentCharacter','@')
set(h_fig(dup),'CurrentCharacter','@')
delete(h_text)
h_text = text(.5,.5,conttxt,txtparams); % display continue text
CloneFig(h_fig(stim),h_fig(dup))
pause(1)
delete(h_text)                          % clear continue text
CloneFig(h_fig(stim),h_fig(dup))
pause(1)