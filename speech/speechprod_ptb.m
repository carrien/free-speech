function [ ] = speechprod_ptb(p)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

allWords = p.allWords;
bListen = p.bListen;
bufsize = 10;

%% setup
% psychtoolbox
AssertOpenGL; % Running on PTB-3? Abort otherwise.
while KbCheck; end; % Wait for release of all keys on keyboard

% audio
InitializePsychSound;   % initialize sound driver
paMode_playback = 1;    % audio playback
paMode_record = 2;      % audio capture
%paMode_simult = 3;      % simultaneous audio capture and playback
if IsWin
    latencyClass = 0;   % no low-latency mode, for now (need ASIO)
else
    latencyClass = 1;   % try low-latency mode
end
fs = 11025;             % sampling rate
nchannels = 2;          % stereo capture
bufsize = 10;           % 10-second buffer

% trigger
if(usetrigs)
    di = DaqDeviceIndex;
    DaqDConfigPort(di,0,0);
    DaqDOut(di,0,0);
else
    di=0;
end

%% experiment
try
    %% setup screen, display intro text
    % Choose display (highest dislay number is a good guess)
    screens=Screen('Screens');
    screenNumber=max(screens);
    win = Screen('OpenWindow', screenNumber);
    Screen('FillRect', win, [0 0 0]);
    Screen('TextFont', win, 'Arial');
    
    Screen('TextSize', win, instructtextsize);
    DrawFormattedText(win,'Please wait.','center','center',[255 255 255]);
    Screen('Flip',win);
    KbWaitForSpace;
    Screen('Flip',win);
    
    %% display experiment text: SPEAK CONDITION
    pahandle = PsychPortAudio('Open', [], paMode_record, latencyClass, fs, nchannels);
    PsychPortAudio('GetAudioData', pahandle, bufsize);
    
    % display words
    allWords = zeros(1,ntrials);
    stimtimes_speak = zeros(1,ntrials);
    rectimes_speak = zeros(1,ntrials);
    stimtimes_listen = zeros(1,ntrials);
    rectimes_listen = zeros(1,ntrials);
    jitter = zeros(1,ntrials);
    
    WaitSecs(1);
    DrawFormattedText(win,'Get ready to SPEAK.','center','center',[255 255 255]);
    Screen('Flip',win);
    KbWaitForKey;
    Screen('Flip',win);
    
    for b=1:nblocks
        WaitSecs(1);
        Screen('TextSize', win, textsize);
        rp = ceil(randperm(nbtrials)./(nbtrials/length(wordbank)));
        allWords(1+nbtrials*(b-1):nbtrials*b) = wordbank(rp);
        for w=1:nbtrials
            t = w+(b-1)*nbtrials; % current trial number
            
            % put text in buffer
            DrawFormattedText(win,words{allWords(t)},'center','center',[255 255 255]);
            
            % start recording
            rectimes_speak(t) = PsychPortAudio('Start', pahandle, 0, 0, 1);
            
            % draw text to screen
            stimtimes_speak(t) = Screen('Flip',win);
            
            % send trigger for visual stim
            trig2send = allWords(t) + trigoffset;
            trigger_meg(di,trig2send,usetrigs);
            
            if ~manualmode
                WaitSecs(stimdur);
            else
                tic;
                KbWait([],[],GetSecs+bufsize-interstimdur-interstimjitter);
                stimdurs(t) = toc;
            end
            
            % clear screen
            Screen('Flip',win);
            WaitSecs(interstimdur);
            
            % stop recording; retrieve & save audio data
            PsychPortAudio('Stop', pahandle);
            audiodata = PsychPortAudio('GetAudioData', pahandle);
            data(t).signalIn = audiodata(1,:)';
            data(t).params.fs = fs;
            
            % add jitter
            jitter(t) = rand*interstimjitter;
            WaitSecs(jitter(t));
        end
        
        % at end of block
        % save data
        save(fullfile(dataPath,'expt.mat'),'expt','allWords');
        save(fullfile(dataPath,'data.mat'),'data');
        % display break or end-of-experiment text
        Screen('TextSize', win, instructtextsize);
        if b < nblocks
            breaktext = sprintf('Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.',t,ntrials);
        else
            breaktext = 'Thank you!\n\n\n\nPlease wait.';
        end
        DrawFormattedText(win,breaktext,'center','center',[255 255 255]);
        Screen('Flip',win);
        if b < nblocks
            KbWaitForKey;
        else
            KbWaitForSpace;
        end
        Screen('Flip',win);
    end
    
    % close audio device
    PsychPortAudio('Close', pahandle);
    %% output experiment log
    vowels = cell(size(words));
    for w=1:length(words)
        vowels{w} = txt2arpabet(words{w});
    end
    if length(vowels) < length(unique(vowels)), % only resort if duplicates
        vowels = unique(vowels);
    end
    
    listWords = words(allWords);
    listVowels = txt2arpabet(listWords);
    
    allVowels = zeros(size(allWords));
    for w=1:length(allWords)
        allVowels(w) = find(strcmp(listVowels{w},vowels));
    end
    
    clear expt
    expt.name = 'aphSIS';
    expt.snum = snum;
    expt.dataPath = dataPath;
    expt.conds = condnames;
    expt.words = words;
    expt.vowels = vowels;
    expt.ntrials = ntrials;
    expt.nblocks = nblocks;
    expt.nbtrials = nbtrials;
    expt.allConds = ones(size(allWords));
    expt.allWords = allWords;
    expt.allVowels = allVowels;
    expt.listConds = condnames(expt.allConds);
    expt.listWords = listWords;
    expt.listVowels = listVowels;
    expt.stimtimes_speak = stimtimes_speak;
    expt.rectimes_speak = rectimes_speak;
    expt.stimtimes_listen = stimtimes_speak;
    expt.rectimes_listen = rectimes_speak;
    expt.jitter = jitter;
    expt.inds = get_exptInds(expt,{'conds', 'words', 'vowels'});
    
    % save expt info
    save(fullfile(dataPath,'expt.mat'),'expt');
    
    
    %% display experiment text: LISTEN CONDITION
    pahandle = PsychPortAudio('Open', [], paMode_playback, latencyClass, fs, nchannels);
    
    WaitSecs(1);
    DrawFormattedText(win,'Get ready to LISTEN.','center','center',[255 255 255]);
    Screen('Flip',win);
    KbWaitForKey;
    Screen('Flip',win);
    
    for b=1:nblocks
        WaitSecs(1);
        Screen('TextSize', win, textsize);
        for w=1:nbtrials
            t = w+(b-1)*nbtrials; % current trial number
            %wavfile = fullfile(dataPath,sprintf('%d.wav',t));
            
            % put text in buffer
            DrawFormattedText(win,words{allWords(t)},'center','center',[255 255 255]);
            
            % put audio in buffer
            audiodata = [data(t).signalIn'; data(t).signalIn'];
            audiodata = [audiodata zeros(2,round(fs))]; %#ok<AGROW> % pad buffer with 1s of tacked-on zeros
            PsychPortAudio('FillBuffer', pahandle, audiodata);
            
            % start playback
            rectimes_listen(t) = PsychPortAudio('Start', pahandle, 0, 0, 1);
            
            % draw text to screen
            stimtimes_listen(t) = Screen('Flip',win);
            
            % send trigger for visual stim
            trig2send = allWords(t)+length(words) + trigoffset;
            trigger_meg(di,trig2send,usetrigs);
            
            if ~manualmode
                WaitSecs(stimdur);
            else
                WaitSecs(stimdurs(t));
            end
            
            % clear screen
            Screen('Flip',win);
            WaitSecs(interstimdur);
            
            % stop playback
            PsychPortAudio('Stop', pahandle);
            
            % add jitter
            WaitSecs(jitter(t));
        end
        
        % at end of block, display break or end-of-experiment text
        Screen('TextSize', win, instructtextsize);
        if b < nblocks
            breaktext = sprintf('Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.',t,ntrials);
        else
            breaktext = 'Thank you!\n\n\n\nPlease wait.';
        end
        DrawFormattedText(win,breaktext,'center','center',[255 255 255]);
        Screen('Flip',win);
        if b < nblocks
            KbWaitForKey;
        else
            KbWaitForSpace;
        end
        Screen('Flip',win);
    end
    
    %% end expt
    Screen('CloseAll');
    
catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
