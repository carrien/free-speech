function [screenNumber, expt] = get_ptb_screenNum(expt)
% TODO header

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
while ~bGoodScreen
    % user input for screen # to test
    screenNumber = askNChoiceQuestion('Enter screen # to try:', {'0' '1' '2' '3' '4'});
    screenNumber = str2double(screenNumber);
    if screenNumber > max(screens)
        fprintf('Error! Max screen number is %d\n', max(screens));
        continue;
    end

    % open screen
    win = Screen('OpenWindow', screenNumber);

    % display text
    Screen('FillRect', win, [0 0 0]);
    Screen('TextFont', win, 'Arial');
    Screen('TextSize', win, 50);
    DrawFormattedText(win, sprintf('This is a test. Screen will close momentarily.'), 'center', 'center', [255 255 255]);
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
