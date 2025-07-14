function [screenNumber, expt] = get_ptb_screenNum(expt)
% Allows user to test which Psychtoolbox screen number corresponds to a
% physical screen. Returns the number of the chosen Psychtoolbox screen.
% Can be used mid-experiment to populate expt.win with correct value.

if nargin < 1 || isempty(expt) || ~isfield(expt, 'win')
    expt.win = [];
end

% PTB setup
Screen('Preference', 'VisualDebuglevel', 1);
Screen('Preference', 'SkipSyncTests', 1);
screens=Screen('Screens');

% if user already knows which screen to use, skip test
knowScreenResp = input('\n\nInput Psychtoolbox screen #, or press Enter to test: ', 's');
if ~isempty(knowScreenResp) && isnumeric(str2double(knowScreenResp)) && ~isnan(str2double(knowScreenResp))
    screenNumber = str2double(knowScreenResp);
    if screenNumber > max(screens) || screenNumber < 0
        bGoodScreen = 0;
        fprintf('Max screen # is %d and you entered %d. Proceeding to test.\n', max(screens), screenNumber);
    else
        bGoodScreen = 1;
    end
else
    fprintf('Proceeding to test.\n');
    bGoodScreen = 0;
end

%% test screen #

% determine possible screen numbers to show to user
for i = 1:length(screens)
    screenNumOptions{i} = num2str(screens(i));
end

% find good screen number
while ~bGoodScreen
    % user input for screen # to test
    screenNumber = askNChoiceQuestion('Enter screen # to try:', screenNumOptions);
    screenNumber = str2double(screenNumber);

    % open screen
    win = Screen('OpenWindow', screenNumber);

    % display text
    Screen('FillRect', win, [255 255 255]);
    Screen('TextFont', win, 'Arial');
    Screen('TextSize', win, 50);
    DrawFormattedText(win, sprintf('This is a test. Screen will close momentarily.'), 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    WaitSecs(2.5);
    Screen('Flip', win);
    WaitSecs(0.5);
    Screen('CloseAll');

    % evaluate screen #
    goodScreenResp = askNChoiceQuestion(sprintf('\nWas screen #%d the right screen?', screenNumber), {'y' 'n'});
    if strcmp(goodScreenResp, 'y')
        bGoodScreen = 1;
    else
        bGoodScreen = 0;
    end
end

%% set output arguments
expt.win = screenNumber;

end
