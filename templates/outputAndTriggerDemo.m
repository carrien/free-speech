function returnedData = outputAndTriggerDemo(inputDevice, outputDevice, numTrials, trialDur, triggerLevel)
% This demo presents continuous noise, then initiates a number of trials.
% During the trial, if your signal through the mic rises above the
% specified intensity threshold, you'll hear a sound instantly.
% 
% This demo attempts to show how Psychtoolbox is used for sound playback,
% audio capture, a parent device with multiple children, polling 'while'
% loops, triggering an event based on a mic signal (speech), and rough
% software lag estimates.
%
% % Input arguments:
% INPUTDEVICE: the microphone that will capture audio. Pass in the numeral ID
% which matches an ID when calling PsychPortAudio('GetDevices'). 
%
% OUTPUTDEVICE: The speaker that will present audio. Pass in the numeral ID
% which matches an ID when calling PsychPortAudio('GetDevices').
%
% NUMTRIALS: How many trials to present in sequence.
%
% TRIALDUR: The duration of each trial in seconds. Whether a response is
% received or not, after trialDur seconds, the trial ends.
%
% TRIGGERLEVEL: When the intensity of the audio input exceeds the trigger
% level, the triggered events will occur. Enter a number from 0 to 1.
%
% % Similar demos released by Psychtoolbox reference:
% SimpleVoiceTriggerDemo.m
% BasicSoundOutputDemo.m
% BasicSoundInputDemo.m
% BasicAMAndMixScheduleDemo.m
%
% v1 5/8/2020 CWN

%% Input arg handling
% Get device info in struct. For Windows, only use WASAPI-type devices.
deviceList = PsychPortAudio('GetDevices');
if nargin < 1 || isempty(inputDevice) || length(deviceList) <= inputDevice || deviceList(inputDevice + 1).NrInputChannels < 1
    warning(['Using default microphone. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of mics if you prefer a different one.']);
    inputDevice = [];
end
if nargin < 2 || isempty(outputDevice) || length(deviceList) <= outputDevice || deviceList(outputDevice+1).NrOutputChannels < 1
    warning(['Using default speakers. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of speakers if you prefer a different one.']);
    outputDevice = [];
end
if nargin < 3 || isempty(numTrials), numTrials = 4; end
if nargin < 4 || isempty(trialDur), trialDur = 4; end % in seconds
if nargin < 5 || isempty(triggerLevel), triggerLevel = 0.15; end % from 0-1


%% Set up audio files that will play during expt
try
    wavfilenameNoise = 'C:\Users\Public\Documents\software\current-studies\audapter_demo\mtbabble48k.wav';
catch
    wavfilenameNoise = [PsychtoolboxRoot 'PsychDemos\SoundFiles\funk.wav'];
end

% Read WAV file from filesystem:
[y, ~] = audioread(wavfilenameNoise);
wavedataNoise = y';
nrchannels = size(wavedataNoise,1); % Number of rows == number of channels.

% Make sure we always use 2 channels stereo output.
if nrchannels < 2
    wavedataNoise = [wavedataNoise ; wavedataNoise];
end

% Repeat process for any other sounds you know you'll be playing during
% expt
try
    wavfilenameTrigger = 'C:\Users\Public\Documents\software\free-speech\templates\clap.wav';
    %wavfilenameTrigger = 'C:\Users\Public\Documents\software\free-speech\templates\tipper_cwn.wav';
catch
    wavfilenameTrigger = [PsychtoolboxRoot 'PsychDemos\SoundFiles\phaser.wav'];
end

[y, outputFreq] = psychwavread(wavfilenameTrigger); % in last WAV, get sample rate
wavedataTrigger = y';
nrchannels = size(wavedataTrigger,1);

if nrchannels < 2
    wavedataTrigger = [wavedataTrigger; wavedataTrigger];
    nrchannels = 2; % In last WAV, make sure nrchannels == 2
end

%% Set up devices
% Allocate space for outputData
returnedData.recordedaudio{numTrials} = [];

% Perform basic initialization of the sound driver. Must do this at start
% of each experiment. 1st parameter == 1 to use low latency mode.
InitializePsychSound(1);

% Ideally there's a match across the board for what the sampling rate is.
% If so, can combine 'outputFreq' and 'inputFreq' to just 'freq',
% and don't need this try/catch block at all.
try
   % Open the device (i.e., create the object) for outputting sound to
   % participant. We're using the device for audio output only (3rd == 1),
   % and it's a parent device (3rd == +8). We want low latency (4th == 1).
   % 5th and 6th are frequency and # channels, which should match device.
    paOutputParent = PsychPortAudio('Open', outputDevice, 1+8, 1, outputFreq, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf(['\nCould not open device at wanted playback frequency of %i Hz.\n ' ...
        'Will retry with device default frequency.\n'], outputFreq);
    fprintf('Sound may sound a bit out of tune...\n\n');
    psychlasterror('reset');
    paOutputParent = PsychPortAudio('Open', outputDevice, 1+8, 1, [], nrchannels);
end

% Start parent device immediately, wait for it to be started. We won't stop
% the parent until the end of the session.
PsychPortAudio('Start', paOutputParent, 0, 0, 1);

% Create two child audio devices for sound playback (3rd == 1), with same
% frequency, channel count etc. as parent. Attach them to parent. As they're
% attached to the same sound channels of the parent (actually the same
% single channel), their audio output will mix together:
paOutputNoise = PsychPortAudio('OpenSlave', paOutputParent, 1);
paOutputTrigger = PsychPortAudio('OpenSlave', paOutputParent, 1);

% Set the masterVolume for the master: This volume setting affects all
% attached sound devices. (Scale: 0-1). Then, lower noise volume.
PsychPortAudio('Volume', paOutputParent, 0.5);
PsychPortAudio('Volume', paOutputNoise, 0.25);

% Create audio buffers for any sounds that you want to play during each
% trial, either pre-emptively or in response to the trigger. Fill the
% audio playback buffer with the audio data (wavedata):
PsychPortAudio('FillBuffer', paOutputNoise, wavedataNoise);
PsychPortAudio('FillBuffer', paOutputTrigger, wavedataTrigger);

% Start playing noise, do it for infinite repetitions until stopped 
% (3rd param == 0), and start it immediately (4th param == 0). (5th == 1)
% means PTB will wait at this point in the function until it expects the
% sound to leave the speaker. This 'Start' call returns a timestamp if desired.
PsychPortAudio('Start', paOutputNoise, 0, 0, 1);

% Open the microphone. We're only capturing audio (3rd param == 2), we want
% low latency (4th param defaults to 1), it's recording at the device's
% default frequency (5th param == []), using 2 channels (6th).
% NOTE: Use 'outputfreq' here if you're recording something here and then
% playing it right back to the participant with the outputDevice.
paInputHandle = PsychPortAudio('Open', inputDevice, 2, [], [], 2);

% Preallocate an internal audio recording buffer with a generous capacity.
PsychPortAudio('GetAudioData', paInputHandle, trialDur*2);

%%
% For each trial, we start recording and check the speaker's volume every 
% 1 ms. Meanwhile, we're saving the microphone's data to recordedaudio.
for trialNum = 1:numTrials
    % We'll be adding to recordedaudio throughout the trial
    recordedaudio = [];
    fprintf('\nGet ready to talk!\n')
    WaitSecs(1);
    
    % Start recording. Continue recording indefinitely.
    tCaptureStart = PsychPortAudio('Start', paInputHandle, 0, 0, 1);
    
    % Wait in a polling loop until some sound event of sufficient loudness
    % is captured. Also check for if n seconds have passed
    level = 0;
    tMaxEnd = tCaptureStart + trialDur;
    
    %Prompt user
    fprintf('----->Say something!<-----\n')
    
    % Repeat as long as below trigger-threshold for intensity:
    while level < triggerLevel && GetSecs < tMaxEnd
        % Fetch current audiodata:
        [audiodata, offset, overflow]= PsychPortAudio('GetAudioData', paInputHandle);
            %Note: `offset` is a rough estimate of when the sample being
            %processed will leave the device (est. hardware lag)
        tInLoop = GetSecs();

        % Compute maximum signal amplitude in this chunk of data:
        if ~isempty(audiodata)
            level = max(abs(sum(audiodata)));
        else
            level = 0;
        end

        % Each time you 'GetAudioData', it pulls all the audio data out of
        % the buffer AND clears the buffer. So, to store all the audio data,
        % we'll be appending audiodata to recordedaudio after each
        % 'GetAudioData' call.
        recordedaudio = [recordedaudio audiodata];
        
        % Below trigger-threshold?
        if level < triggerLevel
            % Wait one millisecond before next scan:
            WaitSecs(0.001);
        end
        
    end
    
    %% Because the trigger occurred, do X Y Z ...
    % Now, we'll first play the buffered audio. Then report on latencies.
    % Then we'll save the rest of the data and prepare for the next trial.
    if level > triggerLevel  
        % Since we're only requesting 1 repetition (3rd param == 1) of the
        % buffered audio file, we don't need a 'Stop' command later.
        tInitAudio = GetSecs();
        tClapEst = PsychPortAudio('Start', paOutputTrigger, 1, 0, 1);
        
        % Compute absolute event time:
        inputStatus = PsychPortAudio('GetStatus', paInputHandle);
        inputFreq = inputStatus.SampleRate;
        % Find how many samples into the buffer the threshold was reached
        idx = find((abs(sum(audiodata)) >= triggerLevel),1,'first');
        % Find absolute time when threshold exceeded
        tThresholdExceeded = tInLoop - ((length(audiodata) - idx) / inputFreq);
        
        fprintf(['I heard that! \n' ...
            , '* Your voice crossed the intensity threshold at %.5f, \n    which was ' ...
            , '%.5f seconds after audio capture began.\n'],tThresholdExceeded, tThresholdExceeded-tCaptureStart)
        fprintf(['* I estimate %.5f ms of software lag between voice onset\n    ' ...
        'and trigger event initiation (i.e., the clap).\n'], (tInitAudio - tThresholdExceeded)*1000);
        fprintf(['* PTB estimates %.4f ms of hardware lag between \n    ' ...
        'initiating the trigger event (clap) and it leaving the speakers.\n'], ...
            (tClapEst-tInitAudio)*1000);
        fprintf('* Total estimated lag: %.4f milliseconds.\n',(tClapEst - tThresholdExceeded)*1000);
            
    else
        fprintf('I didn''t hear anything that time...\n')
    end
    
    % No new commands until the end of the trial duration
    if GetSecs < (tCaptureStart + trialDur)
        WaitSecs('UntilTime', (tCaptureStart + trialDur));
    end
    
    % Stop capturing audio
    PsychPortAudio('Stop', paInputHandle);

    % Fetch all remaining audio data out of the buffer - Needs to be empty
    % before next trial. Then make sure everything's in recordedaudio, and
    % put that trial's recorded audio in the struct this function returns.
    audiodata = PsychPortAudio('GetAudioData', paInputHandle);
    recordedaudio = [recordedaudio audiodata];
    returnedData.recordedaudio{trialNum} = recordedaudio;
    
    % Hopefully this never happens, but alert the user just in case.
    if overflow == 1
        warning(["Overflow occurred. Insufficient buffer allocated between " ...
            "trials. Some recorded audio may have been lost."])
    end
    
    % If we wanted to abort the triggered audio playback, even though it
    % hasn't finished what the 'Start' command told it to do, use this:
    % `PsychPortAudio('Stop', paOutputTrigger)`
    
    fprintf('Trial %d of %d complete.\n', trialNum, numTrials)
    WaitSecs(1);
    
end

%% Close up shop

% Continually poll the device's status. Once s.Active == 0 (i.e., it's not
% playing audio), close the device.
while 1
    s = PsychPortAudio('GetStatus', paOutputTrigger);
    if ~s.Active 
        PsychPortAudio('Close', paOutputTrigger);
        break
    end
    WaitSecs(0.1); %wait 100 ms, then check the status again
end

PsychPortAudio('Stop', paOutputNoise);
PsychPortAudio('Close', paOutputNoise);

PsychPortAudio('Stop', paOutputParent);
PsychPortAudio('Close', paOutputParent);
fprintf('Demo complete. \n \n \n')

end