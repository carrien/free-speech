function [] = pause_trial_ptb(h_fig,instruct)

if nargin < 2 || isempty(instruct)
    % instruction text params
    instruct.pausetxt = 'Paused. Press the space bar to continue.';
    instruct.conttxt = 'We will now continue.';
    instruct.txtparams.FontSize = 60;
end

get_figinds_audapter;
TextSize = Screen('TextSize', h_fig); % current text size

% display pause text and wait for keypress
Screen('TextSize',h_fig,instruct.txtparams.FontSize); % set instruction font size
DrawFormattedText(h_fig,instruct.pausetxt,'center','center',[255 255 255]);
Screen('Flip',h_fig);
KbWaitForSpace;
%CloneFig(h_fig(stim),h_fig(dup))

% resume after keypress
Screen('Flip',h_fig);
DrawFormattedText(h_fig,instruct.conttxt,'center','center',[255 255 255]);
Screen('Flip',h_fig);
%CloneFig(h_fig(stim),h_fig(dup))
WaitSecs(1)
Screen('Flip',h_fig);                      % clear continue text
%CloneFig(h_fig(stim),h_fig(dup))
WaitSecs(1)

Screen('TextSize', h_fig, TextSize);       % reset text size