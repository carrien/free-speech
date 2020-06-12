function timeReactDemo(noiseYN, nTrials, trialDur, micThresh, mode, triggerDelay, inputDeviceID, outputDeviceID, gotchaRatio, dictType)
% A demo to see how quickly people can react to their target word changing
%
% Input arguments:
% 1.) NOISEYN: If 1, white noise will play through the output device. Defaults
% to 0, no noise.
% 2.) NTRIALS: Number of trials.
% 3.) TRIALDUR: How long each trial should wait for a voice onset.
% 4.) MICTHRESH: From 0-1, the intensity level your mic must pick up to
% trigger the word to flip. Lower values = more sensitive mic. Try 0.1 if
% unsure.
% 5.) MODE: Either 'switcheroo' or 'fill'. Fill-in-the-blank will show
% you a base word (cat) then sometimes extend that word (catfish).
% Switcheroo will show you a full-length word (catfish), then sometimes
% switch to another full-length word with the same beginning (cataract).
% 6.) TRIGGERDELAY: The number of seconds of lag you want to add between
% voice onset and the word flipping. Defaults to 0.
% 7.) INPUTDEVICEID: The Psychportaudio device ID associated with the mic
% you want to use. Try devices = Psychportaudio('GetDevices');
% 8.) OUTPUTDEVICEID: The Psychportaudio device ID associated with the
% headphones you want to use. Try devices = Psychportaudio('GetDevices');
% 9.) GOTCHARATIO: From 0 (never) to 1 (always), how often you want the
% demo to flip to a different word after voice onset.
% 10.) DICTTYPE: Which dictionary of words you want the demo to use as
% stimulus words. Currently, there's 'cat' and 'clam'. You can add your own
% list in the 'Dictionary' section of the code
% 
% 
%
% CWN 6/2020

% TODO add other validation checks for mode if it's entered correctly

%% Input arg handling
if nargin < 1 || isempty(noiseYN), noiseYN = 0; end
if nargin < 2 || isempty(nTrials), nTrials = 10; end
if nargin < 3 || isempty(trialDur), trialDur = 2; end
if nargin < 4 || isempty(micThresh), micThresh = 0.1; end
if nargin < 5 || isempty(mode), mode = getMode(); end 
if nargin < 6 || isempty(triggerDelay), triggerDelay = 0; end    
deviceList = PsychPortAudio('GetDevices');
if nargin < 7 || isempty(inputDeviceID) || length(deviceList) <= inputDeviceID || deviceList(inputDeviceID + 1).NrInputChannels < 1
    warning(['Using default microphone. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of mics if you prefer a different one.']);
    inputDeviceID = [];
end
if nargin < 8 || isempty(outputDeviceID) || length(deviceList) <= outputDeviceID || deviceList(outputDeviceID+1).NrOutputChannels < 1
    warning(['Using default speakers. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of speakers if you prefer a different one.']);
    outputDeviceID = [];
end
if nargin < 9 || isempty(gotchaRatio), gotchaRatio = 0.5; end
if nargin < 10 || isempty(dictType), dictType = 'cat'; end

%% Psychtoolbox setup for playback and capture
InitializePsychSound(1);

% Only set up output device if we're playing noise
if noiseYN == 1
    try
        wavfilenameNoise = 'C:\Users\Public\Documents\software\current-studies\audapter_demo\mtbabble48k.wav';
        [y, outputFreq] = audioread(wavfilenameNoise);
    catch
        wavfilenameNoise = fullfile(PsychtoolboxRoot,'PsychDemos','SoundFiles','funk.wav');
        [y, outputFreq] = audioread(wavfilenameNoise);
    end
    
    % Read WAV file from filesystem:
    wavedataNoise = y';
    nrchannels = size(wavedataNoise,1); % Number of rows == number of channels.
    
    % Make sure we always use 2 channels stereo output.
    if nrchannels < 2
        wavedataNoise = [wavedataNoise ; wavedataNoise];
        nrchannels = 2;
    end
    
    try
        outputDevice = PsychPortAudio('Open', outputDeviceID, 1, 1, outputFreq, nrchannels);
    catch
        % Failed. Retry with default frequency as suggested by device:
        fprintf(['\nCould not open device at wanted playback frequency of %i Hz.\n ' ...
            'Will retry with device default frequency.\n'], outputFreq);
        fprintf('Sound may sound a bit out of tune...\n\n');
        psychlasterror('reset');
        outputDevice = PsychPortAudio('Open', outputDeviceID, 1, 1, [], nrchannels);
    end
    
    PsychPortAudio('FillBuffer', outputDevice, wavedataNoise);
    PsychPortAudio('Start', outputDevice, 0, 0, 1);
    PsychPortAudio('Volume', outputDevice, 0.5);
end

% PTB setup for microphone. Needed for vocal onset trigger.
inputDevice = PsychPortAudio('Open', inputDeviceID, 2, [], [], 2);
PsychPortAudio('GetAudioData', inputDevice, trialDur*2); % preallocate buffer

%% Set up words for expt -- Dictionary
% The possible words that will show up as stimuli
% WHEN MAKING NEW DICTS, first cell must be the base word
catDict = {'cat', 'catfish', 'catbus', 'cataract', 'catty', 'cats', 'catnip'};
clamDict = {'clam', 'clams', 'clammy', 'clambor', 'clamor', 'clamp', 'clamshell', 'clam chowder'};
seaDict = {'sea','seagull','seaplane'};
flashDict = {'flash','flashlight','flashback'};
sedDict = {'sed','sediment','sedative'};
switch dictType
    case 'cat'
        dictionary = catDict;
    case 'clam'
        dictionary = clamDict;
    case 'sea'
        dictionary = seaDict;
    case 'flash'
        dictionary = flashDict;
    case 'sed'
        dictionary = sedDict;
    otherwise
        error('Unrecognized stimulus set (%s)',dictType)
end

a1{nTrials} = []; % Pull 1 word per trial from this array to show to pt initially
a2{nTrials} = []; % After vocal onset, switch to corresponding word in this array

%generate list of trials with a switch
gotchaTrials = randperm(nTrials,floor(gotchaRatio*nTrials));
a2{1} = a1{1}; % never switch on first trial

for i = 2:nTrials
    if strcmp(mode, 'fill') % first word is always base word ('cat')
        a1{i} = dictionary{1};
    elseif strcmp(mode,'switcheroo') % first word is a random word from dictionary
        dictIndex = ceil(rand*length(dictionary));
        a1{i} = dictionary{dictIndex};
    elseif strcmp(mode,'cutoff') % first word is random, but never the base word
        dictIndex = ceil(1 + (rand*(length(dictionary) - 1))); 
        a1{i} = dictionary{dictIndex};
    end
    
    a2{i} = a1{i}; % Default to word 2 being the same as word 1
    
    % If you randomly roll below the gotchaRatio, do something different to
    % the second word.
    if any(i == gotchaTrials)
        if strcmp(mode, 'fill') || strcmp(mode, 'switcheroo')
            while strcmp(a2{i}, a1{i}) % If you land on the same word, roll again until you don't
                dictIndex = ceil(rand*length(dictionary));
                a2{i} = dictionary{dictIndex};
            end
        elseif strcmp(mode, 'cutoff')
            a2{i} = dictionary{1};
        end
    end
end

%% Setup for screens
% setup figures
%close all;
sca;
Screen('Preference', 'VisualDebuglevel', 1);
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
% Set the blend function for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[xCenter, ~] = RectCenter(windowRect);
Screen('TextSize', window, 100)


%% Start the experiment
for trialNum = 1:nTrials
    [~,~,keyCode] = KbCheck;
    if keyCode(KbName('escape'))
        sca;
        break;
    end
    WaitSecs(0.75);
    txt2display = a1{trialNum};
    % Display text
    DrawFormattedText(window, txt2display, xCenter/2, 'center', white);
    Screen('Flip', window);
    
    tCaptureStart = PsychPortAudio('Start', inputDevice, 0, 0, 1);
    level = 0;
    tMaxEnd = tCaptureStart + trialDur;
    
    while level < micThresh && GetSecs < tMaxEnd
        % Fetch current audiodata:
        [audiodata]= PsychPortAudio('GetAudioData', inputDevice);
        % Compute maximum signal amplitude in this chunk of data:
        if ~isempty(audiodata)
            level = max(abs(sum(audiodata)));
        else
            level = 0;
        end
        if level < micThresh
            WaitSecs(0.002);
        end
    end
    
    if level > micThresh % If voice onset occurred, do stuff
        % If you want lag between VO and word switch, pause here
        WaitSecs(triggerDelay);
        % Display the word from a2, which maybe is the same, maybe is different
        txt2display = a2{trialNum};
        DrawFormattedText(window, txt2display, xCenter/2, 'center', white);
        Screen('Flip', window);
        fprintf('Trial %i: %s --> %s\n', trialNum, a1{trialNum}, a2{trialNum});
    else
        fprintf('Trial %i: %s --> [No trigger heard]\n', trialNum, a1{trialNum});
    end
    
%     % No new commands until the end of the trial duration
     if GetSecs < (tCaptureStart + trialDur)
         WaitSecs('UntilTime', (tCaptureStart + trialDur));
     end
%    if GetSecs < (tCaptureStart + trialDur)
%        pause((tCaptureStart + trialDur) - GetSecs)
%    end
    
    % Stop capturing audio
    PsychPortAudio('Stop', inputDevice);
    audiodata = PsychPortAudio('GetAudioData', inputDevice); %Clear buffer
    
    % Clear screen again
    txt2display = '';
    DrawFormattedText(window, txt2display, xCenter/2, 'center', white);
    Screen('Flip', window);
end

%% Close audio devices
if noiseYN == 1
    PsychPortAudio('Stop', outputDevice);
    PsychPortAudio('Close', outputDevice);
end
PsychPortAudio('Close', inputDevice);

fprintf('Demo complete. \n\n')
close all;
sca;



    function mode = getMode()
        mode = '';
        while ~strcmp(mode,'switcheroo') && ~strcmp(mode,'fill') && ~strcmp(mode, 'cutoff')
            reply = input(['Which mode would you like to use?' ...
                '\n  For switcheroo, enter 1. For fill-in-the-blank, enter 2. For cutoff, enter 3.' ...
                '\n  Need help? enter help.\n'], 's');
            if strcmp(reply, '1')
                mode = 'switcheroo';
            elseif strcmp(reply, '2')
                mode = 'fill';
            elseif strcmp(reply, '3')
                mode = 'cutoff';
            elseif strcmp(reply, 'help')
                fprintf(['\n    Switcheroo will show you some word (catfish), then it may switch to a \n' ...
                    '     different word with the same beginning (cataract). \n    Fill in the blank ' ...
                    'will always show you the same word to start (cat),\n     and sometimes ' ...
                    'will switch to a longer word with the same beginning (catfish).\n' ...
                    '    Cutoff will show you a long word (catfish), then sometimes will \n' ...
                    '     truncate all but the first part (cat).\n\n']);
                mode = '';
            else
                mode = '';
            end
        end
        fprintf('Mode set to %s\n', mode)
    end
       
end


