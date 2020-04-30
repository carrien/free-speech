function outputData = cwn_OutputAndTriggerDemo(inputDevice, outputDevice, outputDevice2, numTrials, maxTrialDur, triggerLevel)
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


%%      
wavfilename = [PsychtoolboxRoot 'PsychDemos\SoundFiles\funk.wav'];

% Read WAV file from filesystem:
[y, freq] = audioread(wavfilename);
wavedata = y';
nrchannels = size(wavedata,1); % Number of rows == number of channels.

% Make sure we have always 2 channels stereo output.
% Why? Because some low-end and embedded soundcards
% only support 2 channels, not 1 channel, and we want
% to be robust in our demos.
if nrchannels < 2
    wavedata = [wavedata ; wavedata];
    nrchannels = 2;
end

% Allocate space for outputData
outputData.recordedaudio{numTrials} = [];

% Perform basic initialization of the sound driver. Recommend doing this at
% start of each experiment. Call w/ 1st parameter == 1 for low latency
% mode (Not sure if that actually changes anything though).
InitializePsychSound(1);

% Open the device (i.e., create the object) for outputting sound to participant
try
    % Try with the 'freq'uency we wanted:
    %paOutputHandle = PsychPortAudio('Open', outputDevice, [], 2, freq, nrchannels);
        % TODO remove after implementing parent/child
    % TODO add description for parent 'Open' call
    paOutputHandle = PsychPortAudio('Open', outputDevice, 1+8, 1, freq, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf(['\nCould not open device at wanted playback frequency of %i Hz.' ...
        'Will retry with device default frequency.\n'], freq);
    fprintf('Sound may sound a bit out of tune, ...\n\n');

    psychlasterror('reset');
    %paOutputHandle = PsychPortAudio('Open', outputDevice, [], 2, [], nrchannels);
        % TODO remove after implementing parent/child
    paOutputHandle = PsychPortAudio('Open', outputDevice, 1+8, 1, freq, nrchannels);
end

% Get what frequency we are actually using:
s = PsychPortAudio('GetStatus', paOutputHandle);
freq = s.SampleRate;



% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', paOutputHandle, wavedata);


% Start audio playback, do it for infinite repetitions until stopped, 
% (3rd param == 0), and start it immediately (4th param == 0). Optionally,
% output param of 'Start' call is a timestamp.
PsychPortAudio('Start', paOutputHandle, 0, 0, 1);

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
        %
        %
        % Doing a very messy version of triggering audio
        %
        %
        [y, freq] = psychwavread([PsychtoolboxRoot 'PsychDemos\SoundFiles\clap.wav']);
        wavedata = y';
        nrchannels = size(wavedata,1);
            %TODO use 'freq' from file, or default (5th param == [])?
        paOutputHandle2 = PsychPortAudio('Open', outputDevice2, [], 1, [], nrchannels);
        PsychPortAudio('FillBuffer', paOutputHandle2, wavedata);
        clapStart = PsychPortAudio('Start', paOutputHandle2, 1, 0, 1);
        fprintf('clapStart happened at %.4f, which is %.4f ms after tTrigger\n', ...
            clapStart, (clapStart-tTrigger)*1000);
        %
        %
        % End of very messy triggering of audio, except closing them at the
        % end of the fx.
        %
        %
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
    
    % The very messy audio triggering handles are closed here 
    if triggerOccurred == 1     % TODO remove sloppy triggerOccurred variable
        PsychPortAudio('Stop', paOutputHandle2);
        PsychPortAudio('Close', paOutputHandle2);
    end
end


PsychPortAudio('Stop', paOutputHandle);
PsychPortAudio('Close', paOutputHandle);
fprintf('Demo complete. \n \n \n')

end