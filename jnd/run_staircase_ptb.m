function [expt] = run_staircase_ptb(expt)
% Psych toolbox engine for running the cerebellar vowel duration perception task (accompanies cerebTimeAdapt) 

%% Set up datapath
if ~exist(expt.dataPath, 'dir'), mkdir(expt.dataPath); end
save(fullfile(expt.dataPath, 'expt.mat'), 'expt'); 


%% Set up peripherals (screens, audio device) 

% Choose display (highest dislay number is a good guess)
Screen('Preference', 'SkipSyncTests', 1);
screens=Screen('Screens');
screenNumber=max(screens);
if ~isfield(expt, 'win') % Should also check that the window actually exists
    win = Screen('OpenWindow', screenNumber);
    expt.win = win; 
else
    win = expt.win; 
end

% Set audio device 
InitializePsychSound;   % set up Psychtoolbox audio mex
wasapiDevices = PsychPortAudio('GetDevices',13);
deviceNames = {wasapiDevices.DeviceName}; 
scarletts = find(contains(deviceNames, 'Focusrite')); 
outputDevs = find([wasapiDevices.NrOutputChannels] > 0); 
outputScarlett = intersect(outputDevs, scarletts); 

% Parameters for audio output 
paMode = 1;              % only audio playback
latencyClass = 0;    % This is "take full control of audio device, request most aggressive settings for device, fail if can't meet strictest reqs" 
% Note: we can't use 1 because we don't have ASIO drivers. 
% Other option is 0, which is "don't care about it being well-timed". Probably not ideal for this project. 
fs = expt.fs; 
nchannels = 2; 

h_stimulusOutput = PsychPortAudio('Open', wasapiDevices(outputScarlett).DeviceIndex, paMode, latencyClass, fs, nchannels);

answerKeys = [KbName(expt.leftKey) KbName(expt.rightKey)];
continueKey = KbName('space'); 
%% Initialize instructions

% Set font parameters
Screen('TextFont', win, 'Arial');
Screen('TextSize', win, expt.instruct.txtparams.FontSize);

% Black screen
Screen('FillRect', win, [0 0 0]);
Screen('Flip',win);

if strcmp(expt.conds, 'pre')
    % Display instructions
    DrawFormattedText(win,expt.instruct.introtxt,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
    Screen('Flip',win);
    RestrictKeysForKbCheck(continueKey);
    ListenChar(1)
    tStart = GetSecs;
    timedout = 0;
    while ~timedout
        % Wait for spacebar
        [ keyIsDown, keyTime, keyCode ] = KbCheck;
        if keyIsDown, break; end
        rt = keyTime - tStart;
        if rt > expt.t2wait.break, timedout = 1; end
    end

    Screen('FillRect', win, [0 0 0]);
    Screen('Flip',win);
end

clear keyIsDown keyTime rt
pause(0.5); % Give variables time to clear 

% Say whether or not there will be feedback (practice vs. full)
if expt.bDisplayFeedback    
    DrawFormattedText(win, expt.instruct.feedbackY, 'center', 'center', [255 255 255], expt.instruct.txtparams.wrapat);    
else
    DrawFormattedText(win, expt.instruct.feedbackN, 'center', 'center', [255 255 255], expt.instruct.txtparams.wrapat);
end
Screen('Flip',win); 
RestrictKeysForKbCheck(continueKey); 
ListenChar(1); 
tStart = GetSecs; 
 timedout = 0;
while ~timedout
    % Wait for spacebar
    [ keyIsDown, keyTime, keyCode ] = KbCheck;
    if keyIsDown, break; end
    rt = keyTime - tStart; 
    if rt > expt.t2wait.break, timedout = 1; end
end

Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 

clear keyIsDown keyTime rt
pause(0.5); % Give variables time to clear 
%% Set up whole data structure so you can build/save faster
data(expt.maxTrials).subj = expt.snum; 
data(expt.maxTrials).trial = expt.maxTrials; % I just don't want stepSize to be the first column... 
data(1).stepSize = expt.maxStepSize; 
data(1).previousAnswer = 0; % Just to initiate this
data(1).currentAnswer = 0; 
save(fullfile(expt.dataPath, 'data.mat'), 'data'); 

% Set up key responses
KbName('UnifyKeyNames');


%% Trial loop
itrial = 1; 
nReversals = 0; 
stimSoundFN = repmat({}, 1, length(expt.taskType)); % Empty cell array for the sound file names 
while nReversals < expt.maxReversals && itrial <= expt.maxTrials
    % Add meta information to data structure
    % Meta
    data(itrial).subj = expt.snum;                        % Participant code 
    data(itrial).trial = itrial;                     % Trial number

    fprintf('Starting trial %d/%d, reversals %d/%d\n', itrial, expt.maxTrials, nReversals, expt.maxReversals);

    % Check if catch 
    bCatch = ismember(itrial, expt.catchTrials); 
    data(itrial).reserveStepSize = data(itrial).stepSize;                   % Save what the step size "should be" so you can reference it for next trial if necessary
    data(itrial).bCatch = bCatch; 
    % Add information about the stimuli to the data structure
    % If catch trial, use max step
    if bCatch
        data(itrial).stepSize = expt.maxStepSize;                           % Set this trial's actual step size to max
    end
    % Proceed with setting up trial 
    [lowerDur, upperDur] = get_stimuliBasedOnStep(expt.centerValue, data(itrial).stepSize, expt.bSymmetricalStimuli);
    data(itrial).lowerDur = lowerDur; 
    data(itrial).upperDur = upperDur; 
    [stimSeq, answerPos] = get_stimulusSequence([lowerDur, upperDur], expt.taskType); 
    data(itrial).stimSequence = stimSeq; 
    
    % Get filenames 
    for i = 1:length(stimSeq)
        stimSeqName = num2str(stimSeq(i)); % reduces to 4 decimal pts precision and strips trailing zeros
        stimSeqName = replace(stimSeqName, '.', 'x'); % so 225.5 is 225x5 
        stimSoundFN{i} = [expt.soundfilePrefix stimSeqName expt.soundfileSuffix]; 
    end
    data(itrial).stimFilenames = stimSoundFN; 
    data(itrial).answerPosition = answerPos; % Comes back with 1 or 3 because is AXB 
    
    % Prepare sound buffer
    j = 0;
    nrchannels = 2;
    soundBuffer = [];
    silenceBuffer = []; 
    stimPlaybackDur = 0; 
    for i=1:length(stimSoundFN)
        try
            % Make sure we don't abort if we encounter an unreadable soundfile. This is achieved by the try-catch clauses
            [audiodata, ~] = psychwavread(fullfile(expt.soundfileDir, stimSoundFN{i}));
            dontskip = 1;
        catch
            fprintf('Failed to read and add file %s. Skipped.\n', stimSoundFN{i});
            dontskip = 0;
            psychlasterror
            psychlasterror('reset');
        end
        
        if dontskip
            j = j + 1;
            
            [~, ninchannels] = size(audiodata);
            audiodata = repmat(transpose(audiodata), nrchannels / ninchannels, 1);      % Make sure there are two channels
            audiosize = size(audiodata); 

            % Add to sound buffer 
            soundBuffer(end+1) = PsychPortAudio('CreateBuffer', [], audiodata); %#ok<AGROW>
            fprintf('Filling audiobuffer handle with soundfile %s ...\n', stimSoundFN{i});
            soundDur = audiosize(2)/fs;             
            stimPlaybackDur = stimPlaybackDur + soundDur; 
            
            % Make a jittered silence object 
            if j < length(stimSeq) % Only put in jitters between files (not after the last one) 
                interstimJitter = expt.timing.interstimdur + rand*expt.timing.interstimjitter;  
                interstimJitterData = zeros(nrchannels, round(fs*interstimJitter)); 
                silenceBuffer(end+1) = PsychPortAudio('CreateBuffer', [], interstimJitterData); %#ok<AGROW>
                stimPlaybackDur = stimPlaybackDur + interstimJitter; 
            end
              
        end
    end
    
    % Recompute number of available sounds:
    nfiles = length(soundBuffer);
    PsychPortAudio('UseSchedule', h_stimulusOutput, 1);    
    
    % Build an initial play sequence. Consists of soundfile > silence > soundfile > silence... 
    for i=1:nfiles
        PsychPortAudio('AddToSchedule', h_stimulusOutput, soundBuffer(i), 1, 0.0);
        if i <= length(silenceBuffer)
            PsychPortAudio('AddToSchedule', h_stimulusOutput, silenceBuffer(i), 1, 0.0); 
        end
    end
    
    fprintf('\nReady. Beginning now!...\n\n\n');
    
    % Start audio playback
    PsychPortAudio('Start', h_stimulusOutput, [], 0, 1);
    
    % Wait for however long the whole playback is
    WaitSecs(stimPlaybackDur)
        
    % BasicSoundScheduleDemo_noloop(expt,wavfilenames)
    %% prompt to press a key
    Screen('TextSize', win, expt.instruct.txtparams.FontSize);
    DrawFormattedText(win,expt.instruct.trial,'center','center',[255 255 255]);
    Screen('Flip',win);
    
    %% Look for answer
    RestrictKeysForKbCheck(answerKeys);
    ListenChar(2) % 2 means their answer won't get put into the matlab command window/other functions
    tStart = GetSecs;
    % repeat until a valid key is pressed or we time out
    timedout = 0;
    while ~timedout
        % check if a key is pressed
        % only keys specified in activeKeys are considered valid
        [ keyIsDown, keyTime, keyCode ] = KbCheck;
        if keyIsDown, break; end
        rt = keyTime - tStart; 
        if rt > expt.t2wait.answer, timedout = 1; end
    end
    % store code for key pressed and reaction time
    if(~timedout)
        data(itrial).rt = keyTime - tStart;
        keyPressed = KbName(keyCode); 
    else
        data(itrial).rt = expt.t2wait.answer+1; 
        keyPressed = 'NaN'; 
    end
    
    % Blackout screen
    Screen('FillRect', win, [0 0 0]);
    Screen('Flip',win); 
    clear keyIsDown keyTime rt
    RestrictKeysForKbCheck([]); % remove restriction
    pause(0.5); % Give variables time to clear 
    
    % reset the keyboard input checking for all keys
    RestrictKeysForKbCheck(answerKeys);
    % re-enable echo to the command line for key presses
    ListenChar(1)

    % Information about the answer
    % Translate keystroke into answer position 
    if strcmp(keyPressed, expt.leftKey)
        data(itrial).response = 1; 
    elseif strcmp(keyPressed, expt.rightKey)
        data(itrial).response = 3; 
    else
        data(itrial).response = NaN; % Timed out responses 
    end
    data(itrial).bCorrect = data(itrial).response == data(itrial).answerPosition; 
    data(itrial).currentAnswer = data(itrial).bCorrect; 
    % Determine if this was a reversal
    if itrial == 1 || bCatch % First trials and catch trials are not
        data(itrial).bReversal = 0;         
    else
        data(itrial).bReversal = double(~isequal(data(itrial).previousAnswer, data(itrial).currentAnswer)); 
    end
    nReversals = nReversals + data(itrial).bReversal; 
    
    % If you're doing the practice round
    if expt.bDisplayFeedback
       if data(itrial).bCorrect
           DrawFormattedText(win, 'Correct!', 'center', 'center', [20 200 20]);
       else
           DrawFormattedText(win, 'Incorrect','center','center',[200 20 20]);
       end
       Screen('Flip',win); 
       WaitSecs(1); 
       Screen('FillRect', win, [0 0 0]);
       Screen('Flip',win); 
    end
    
    % Save most recent trial (there's not a lot of information in here, so it should be able to write every trial no problem)
    save(fullfile(expt.dataPath, 'data.mat'), 'data'); 
    
    %% Check if break trial
    if any(expt.breakTrials == itrial)
        Screen('FillRect', win, [0 0 0]);
        Screen('Flip',win); 
        breaktext = sprintf('Time for a break!\n\nPress the space bar to continue.');
        DrawFormattedText(win, breaktext, 'center', 'center', [255 255 255]);
        Screen('Flip',win); 
        
        RestrictKeysForKbCheck(continueKey);
        ListenChar(1)
        tStart = GetSecs; 
        timedout = 0;
        while ~timedout
            % Wait for spacebar
            [ keyIsDown, keyTime, keyCode ] = KbCheck;
            if keyIsDown, break; end
            rt = keyTime - tStart; 
            if rt > expt.t2wait.break, timedout = 1; end
        end
        Screen('FillRect', win, [0 0 0]);
        Screen('Flip',win); 
        clear keyIsDown keyTime rt
        pause(0.5); % Give variables time to clear 
    end
    
    
    
    
    %% Prepare next trial
    if bCatch
        % If this was a catch, set next trial to the step size this would have been 
        data(itrial+1).stepSize = data(itrial).stepSize;                        
    else
        data(itrial+1).stepSize = get_nextStepSize(expt, data(itrial).stepSize, data(itrial).bCorrect, nReversals); 
    end
    % Store current answer as next trial's previous answer
    
    data(itrial+1).previousAnswer = data(itrial).currentAnswer;                                 
    
    % Increment trial 
    itrial = itrial + 1;                                                                    
   
end

% Display ending text 
Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 
breaktext = sprintf('Thank you!\n\nPlease wait.');
DrawFormattedText(win, breaktext, 'center', 'center', [255 255 255]);
Screen('Flip',win); 
WaitSecs(3); 
Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 


if strcmp(expt.conds, 'full')
    Screen('CloseAll'); 
end

fprintf('Data saved to %s\n', fullfile(expt.dataPath, 'data.mat'));



end