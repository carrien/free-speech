function outputData = cwn_OutputAndTriggerDemo(inputDevice, outputDevice, numTrials, maxTrialDur, triggerLevel)
% Function description
%
% % Input arguments:
% INPUTDEVICE: the microphone that will capture audio. Can pass in the
% ID as a numeral or the first part of the name (case sensitive). 
%
% OUTPUTDEVICE: The speaker that will present audio. Can pass in the ID as
% a numeral or the first part of the name (case sensitive). 
%
% NUMTRIALS: How many trials to present in sequence. Defaults to 4.
%
% MAXTRIALDUR: The max duration in seconds for each trial. After this
% amount of time, end the trial even if no trigger occurred.
%
% TRIGGERLEVEL: When the intensity of the audio input exceeds the trigger
% level, the triggered events will occur. Enter a number from 0 to 1.
%
% 

% TODO fix implementation of chooseAudioDevice in input arg handling
% TODO Add scheduling. (Wait until end of trialDur to go to next trial?)
% TODO instead of trigger occurred for closing the child output device,
% should schedule a 'Close' action at end of wavedataTrigger playback
% TODO tTriggerConsequent-tTrigger gives negative results... why...
% TODO 'Stop' call, changing repetitions from 0 to 1.

%% Input arg handling
if nargin < 1 || isempty(inputDevice)
    warning(['Using default microphone. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of mics if you prefer a different one.']);
    inputDevice = [];
end
if nargin < 2 || isempty(outputDevice)
    warning(['Using default speakers. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of speakers if you prefer a different one.']);
    outputDevice = [];
end
if nargin < 3 || isempty(numTrials), numTrials = 4; end
if nargin < 4 || isempty(maxTrialDur), maxTrialDur = 4; end % in seconds
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
wavfilenameTrigger = [PsychtoolboxRoot 'PsychDemos\SoundFiles\clap.wav'];

[y, outputFreq] = psychwavread(wavfilenameTrigger); % in last WAV, get sample rate
wavedataTrigger = y';
nrchannels = size(wavedataTrigger,1);

if nrchannels < 2
    wavedataTrigger = [wavedataTrigger; wavedataTrigger];
    nrchannels = 2; % In last WAV, make sure nrchannels == 2
end

%% Set up devices
% Allocate space for outputData
outputData.recordedaudio{numTrials} = [];

% Perform basic initialization of the sound driver. Must do this at start
% of each experiment. 1st parameter == 1 to use low latency mode.
InitializePsychSound(1);

% Open the device (i.e., create the object) for outputting sound to participant

% Ideally there's a match across the board for what the sampling rate is.
% If so, can combine 'outputFreq' and 'inputFreq' to just 'freq',
% and don't need this try/catch block at all.
try
    % TODO add description for parent 'Open' call
    paOutputParent = PsychPortAudio('Open', outputDevice, 1+8, 1, outputFreq, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf(['\nCould not open device at wanted playback frequency of %i Hz.\n ' ...
        'Will retry with device default frequency.\n'], outputFreq);
    fprintf('Sound may sound a bit out of tune...\n\n');

    psychlasterror('reset');
    paOutputParent = PsychPortAudio('Open', outputDevice, 1+8, 1, [], nrchannels);
end

% Start parent immediately, wait for it to be started. We won't stop the
% master until the end of the session.
PsychPortAudio('Start', paOutputParent, 0, 0, 1);

% Set the masterVolume for the master: This volume setting affects all
% attached sound devices. We set this to 0.5, so it doesn't blow out the
% ears of our listeners...
PsychPortAudio('Volume', paOutputParent, 0.5);

% Create two child audio devices for sound playback (+1), with same
% frequency, channel count et. as parent. Attach them to parent. As they're
% attached to the same sound channels of the parent (actually the same
% single channel), their audio output will mix together:
paOutputChild1 = PsychPortAudio('OpenSlave', paOutputParent, 1);
paOutputChild2 = PsychPortAudio('OpenSlave', paOutputParent, 1);


% Create audio buffers for any sounds that you want to play during each
% trial, either pre-emptively or in response to the trigger. Fill the
% audio playback buffer with the audio data (wavedata):
PsychPortAudio('FillBuffer', paOutputChild1, wavedataNoise);
PsychPortAudio('FillBuffer', paOutputChild2, wavedataTrigger);

% Start playing noise, do it for infinite repetitions until stopped, 
% (3rd param == 0), and start it immediately (4th param == 0). Optionally,
% output param of 'Start' call is a timestamp.
PsychPortAudio('Start', paOutputChild1, 0, 0, 1);

% Open the microphone. We're only capturing audio (3rd param == 2), we want
% low latency (4th param defaults to 1), it's recording at the device's
% default frequency (5th param == []), using 2 channels (6th).
% NOTE: Use 'outputfreq' here if you're recording something here and then
% playing it right back to the participant with the outputDevice.
paInputHandle = PsychPortAudio('Open', inputDevice, 2, [], [], 2);

% Preallocate an internal audio recording buffer with a generous capacity
% of twice the duration of each trial.
trialDur = 5;
PsychPortAudio('GetAudioData', paInputHandle, trialDur*2);

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
    tMaxEnd = tCaptureStart + maxTrialDur;
    
    %Prompt user
    fprintf('----->Say something!<-----\n')
    
    % Repeat as long as below trigger-threshold:
    while level < triggerLevel && GetSecs < tMaxEnd
        % Fetch current audiodata:
        [audiodata, offset, overflow]= PsychPortAudio('GetAudioData', paInputHandle);
        t_timestamp = GetSecs();

        % Compute maximum signal amplitude in this chunk of data:
        if ~isempty(audiodata)
            level = max(abs(sum(audiodata)));
        else
            level = 0;
        end

        % Add audio data from this loop to our running total
        recordedaudio = [recordedaudio audiodata];
        
        % Below trigger-threshold?
        if level < triggerLevel
            % Wait one millisecond before next scan:
            WaitSecs(0.001);
        end
        
    end
    
    %% Because the trigger occurred, do X Y Z ...
    if level > triggerLevel  
        idx = find((abs(sum(audiodata)) >= triggerLevel),1,'first');
        
        % Compute absolute event time:
        inputStatus = PsychPortAudio('GetStatus', paInputHandle);
        inputFreq = inputStatus.SampleRate;
        tTrigger = tCaptureStart + ((offset + idx - 1) / inputFreq);
        
        fprintf(['I heard that! \n' ...
            , 'The trigger happened at %.4f, which was ' ...
            , '%.4f seconds after the stimulus.\n'],tTrigger, tTrigger-tCaptureStart)
        
        % TODO add documentation here
        % Since we're only requesting 1 repetition (5th param == 1) of the
        % buffered audio file, we don't need a 'Stop' command later.
        tTriggerConsequent = PsychPortAudio('Start', paOutputChild2, 1, 0, 1);
        t_trigger2 = GetSecs();
        fprintf('tTriggerConsequent happened at %.4f, which is %.4f ms after tTrigger\n', ...
            tTriggerConsequent, (tTriggerConsequent-tTrigger)*1000);
        fprintf('t_trigger2 happened at %.4f, which is %.4f ms after t_timestamp\n', ...
            t_trigger2, (t_trigger2-t_timestamp)*1000);
        
        % Tell the device to stop once it's done with the
        % commands we've already given it (3rd param == 1). Since in the
        % 'Start' call we told it to play 1 time, it'll stop after that.
        %PsychPortAudio('Stop', paOutputChild2, 1)
    else
        fprintf('I didn''t hear anything that time...\n')
    end
    
    %Stop capturing audio
    PsychPortAudio('Stop', paInputHandle);

    % Fetch all remaining audio data out of the buffer - Needs to be empty
    % before next trial.
    audiodata = PsychPortAudio('GetAudioData', paInputHandle);
    
    % Put the last scraps of audio in recordedaudio, then put it all in the
    % outputData file that gets returned by the function
    recordedaudio = [recordedaudio audiodata];
    outputData.recordedaudio{trialNum} = recordedaudio;
    
    % Hopefully this never happens, but check just in case.
    if overflow == 1
        warning(["Overflow occurred. Insufficient buffer between trials. " ...
            "Some recorded audio may have been lost."])
    end
    
    %Prep participant for next trial
    fprintf('Trial %d of %d is complete\n', trialNum, numTrials)
    WaitSecs(1.5);
    
end

%% Close up shop

% Continually poll the device's status. Once s.Active == 0 (i.e., it's not
% playing audio), close the device.
while 1
    s = PsychPortAudio('GetStatus', paOutputChild2);
    if ~s.Active 
        PsychPortAudio('Close', paOutputChild2);
        break
    end
    WaitSecs(0.1); %wait 100 ms, then check the status again
end

% TODO try doing a 'stop' call with waitforendofplayback = 3, and set
% repetitions to 1, so it stops after this one. Does that work right away?
% Does it do one last rep after the current one?
PsychPortAudio('Stop', paOutputChild1);
PsychPortAudio('Close', paOutputChild1);

PsychPortAudio('Stop', paOutputParent);
PsychPortAudio('Close', paOutputParent);
fprintf('Demo complete. \n \n \n')

end