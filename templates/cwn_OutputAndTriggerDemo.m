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
% TODO implement master/slave method. See BasicAMAndMixScheduleDemo
    % TODO properly implement playing audio as triggered event    
        % TODO remove sloppy triggerOccurred variable
% Add scheduling. (Wait until end of trialDur to go to next trial?)
% TODO change funk.wav to noise. See mtbabble.wav somewhere? Can ask Sarah
% TODO in 'Open' input device call, change 8th param from 0.02 to something
% lower. That is the suggested latency. See what happens with []?
% TODO instead of trigger occurred for closing the child output device,
% should schedule a 'Close' action at end of wavedataTrigger playback
% TODO figure out why the timestamps are showing up wrong for
% tTriggerConsequent-tTrigger

%% Input arg handling
if nargin < 1 || isempty(inputDevice)
    %inputDevice = chooseAudioDevice('input');
    error("Must include device ID for microphone. Use PsychPortAudio('GetDevices').")
end
if nargin < 2 || isempty(outputDevice)
    %outputDevice = chooseAudioDevice('output');
    error("Must include device ID for speakers/headphones. Use PsychPortAudio('GetDevices').")
end
if nargin < 3 || isempty(numTrials), numTrials = 4; end
if nargin < 4 || isempty(maxTrialDur), maxTrialDur = 4; end % in seconds
if nargin < 5 || isempty(triggerLevel), triggerLevel = 0.15; end % from 0-1


%% Set up audio files that will play during expt
wavfilenameNoise = [PsychtoolboxRoot 'PsychDemos\SoundFiles\funk.wav'];

% Read WAV file from filesystem:
[y, freq] = audioread(wavfilenameNoise);
wavedataNoise = y';
nrchannels = size(wavedataNoise,1); % Number of rows == number of channels.

% Make sure we always use 2 channels stereo output.
if nrchannels < 2
    wavedataNoise = [wavedataNoise ; wavedataNoise];
end

% Repeat process for any other sounds you know you'll be playing during
% expt
wavfilenameTrigger = [PsychtoolboxRoot 'PsychDemos\SoundFiles\clap.wav'];

[y, freq] = psychwavread(wavfilenameTrigger);
wavedataTrigger = y';
nrchannels = size(wavedataTrigger,1);

if nrchannels < 2
    wavedataNoise = [wavedataNoise ; wavedataNoise];
    nrchannels = 2; % In last iteration, make sure nrchannels == 2
end

%% Set up devices
% Allocate space for outputData
outputData.recordedaudio{numTrials} = [];

% Perform basic initialization of the sound driver. Recommend doing this at
% start of each experiment. Call w/ 1st parameter == 1 for low latency
% mode (Not sure if that actually changes anything though).
InitializePsychSound(1);

% Open the device (i.e., create the object) for outputting sound to participant
try
    % Try with the 'freq'uency we wanted:
    % TODO add description for parent 'Open' call
    paOutputParent = PsychPortAudio('Open', outputDevice, 1+8, 1, freq, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf(['\nCould not open device at wanted playback frequency of %i Hz.' ...
        'Will retry with device default frequency.\n'], freq);
    fprintf('Sound may sound a bit out of tune, ...\n\n');

    psychlasterror('reset');
    paOutputParent = PsychPortAudio('Open', outputDevice, 1+8, 1, [], nrchannels);
end

% Get what frequency we are actually using:
s = PsychPortAudio('GetStatus', paOutputParent);
freq = s.SampleRate;

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
% trial, either pre-emptively or in response to the trigger

% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', paOutputChild1, wavedataNoise);

%TODO use 'freq' from file, or default (5th param == [])?
PsychPortAudio('FillBuffer', paOutputChild2, wavedataTrigger);




% Start funky music, do it for infinite repetitions until stopped, 
% (3rd param == 0), and start it immediately (4th param == 0). Optionally,
% output param of 'Start' call is a timestamp.
PsychPortAudio('Start', paOutputChild1, 0, 0, 1);

paInputHandle = PsychPortAudio('Open', inputDevice, 2, 0, [], 2, [], 0.02);

% Preallocate an internal audio recording buffer with a generous capacity
% of twice the duration of each trial.
trialDur = 5;
PsychPortAudio('GetAudioData', paInputHandle, trialDur*2);

for trialNum = 1:numTrials
    % We'll be adding to this throughout the trial
    recordedaudio = [];
    fprintf('\nGet ready to talk!\n')
    WaitSecs(1);
    
    % Start recording. Continue recording indefinitely.
    tCaptureStart = PsychPortAudio('Start', paInputHandle, 0, 0, 1);
    
    %Prompt user
    fprintf('----->Say something!<-----\n')
    %tCaptureStart = GetSecs; % mark the time of stimulus presentation
    
    % Wait in a polling loop until some sound event of sufficient loudness
    % is captured:
    level = 0;

    % also check for if n seconds have passed
    tMaxEnd = tCaptureStart + maxTrialDur;
    
    % Repeat as long as below trigger-threshold:
    while level < triggerLevel && GetSecs < tMaxEnd
        % Fetch current audiodata:
        [audiodata, offset, overflow]= PsychPortAudio('GetAudioData', paInputHandle);

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
            % Wait for five milliseconds before next scan:
            WaitSecs(0.001);
        end
        
    end
    
    %% Because the trigger occurred, do X Y Z ...
    if level > triggerLevel  
        triggerOccurred = 1;
        idx = find((abs(sum(audiodata(1,:))) >= triggerLevel),1,'first');
        
        % Compute absolute event time:
        tTrigger = tCaptureStart + ((offset + idx - 1) / freq);
        
        fprintf(['I heard that! \n' ...
            , 'The trigger happened at %.4f, which was ' ...
            , '%.4f seconds after the stimulus.\n'],tTrigger, tTrigger-tCaptureStart)
        
        % TODO add documentation here
        tTriggerConsequent = PsychPortAudio('Start', paOutputChild2, 1, 0, 1);
        fprintf('tTriggerConsequent happened at %.4f, which is %.4f ms after tTrigger\n', ...
            tTriggerConsequent, (tTriggerConsequent-tTrigger)*1000);
    else
        triggerOccurred = 0;  
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
    
    
    if triggerOccurred == 1     % TODO remove sloppy triggerOccurred variable
        PsychPortAudio('Stop', paOutputChild2);
    end
end

%% Close up shop
PsychPortAudio('Close', paOutputChild2);

PsychPortAudio('Stop', paOutputChild1);
PsychPortAudio('Close', paOutputChild1);

PsychPortAudio('Stop', paOutputParent);
PsychPortAudio('Close', paOutputParent);
fprintf('Demo complete. \n \n \n')

end