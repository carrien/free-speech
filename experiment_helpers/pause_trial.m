function [] = pause_trial(h_fig,params)

get_figinds_audapter;

% text params
% Addition for simonToneLex RK 2022-01-31
if nargin < 2 || isempty(params)
    pausetxt = 'Paused. Press the space bar to continue.';
    conttxt = 'We will now continue.';
else
    pausetxt = params.pausetxt; 
    conttxt = params.conttxt; 
end
txtparams.Color = 'white';
txtparams.FontSize = 60;
txtparams.HorizontalAlignment = 'center';

% display pause text and wait for keypress
figure(h_fig(stim))
h1_sub = subplot(1,1,1);
set(h1_sub, 'color', 'black')
axis off
h_text = text(.5,.5,pausetxt,txtparams);
try CloneFig(h_fig(stim),h_fig(dup)); catch; end
pause

% resume after keypress
try
    set(h_fig(stim),'CurrentCharacter','@')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','@')
    set(h_fig(dup),'CurrentCharacter','@')
catch
end

delete(h_text)
pause(1); 
h_text = text(.5,.5,conttxt,txtparams); % display continue text
try CloneFig(h_fig(stim),h_fig(dup)); catch; fprintf('I''m in the catch for cloning'); end
pause(2)
delete(h_text)                          % clear continue text
try CloneFig(h_fig(stim),h_fig(dup)); catch; end
pause(1)