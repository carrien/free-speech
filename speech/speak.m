function [speak] = speak(snum,dataPath,usetrigs,practicemode,manualmode, expt)
Screen('Preference', 'SkipSyncTests', 1); % added to work on Sarah's office Mac

% psychtoolbox
AssertOpenGL; % Running on PTB-3? Abort otherwise.
while KbCheck; end; % Wait for release of all keys on keyboard (-1,2)

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

% defining expt objects from parent script
ntrials = expt.ntrials;
textsize =   expt.textsize;
instructtextsize = expt.instructtextsize;
nblocks = expt.nblocks;
nbtrials = expt.nbtrials;
words = expt.words;
vowels = expt.vowels;
wordbank = expt.wordbank;
stimdur = expt.stimdur;
interstimdur = expt.interstimdur;
interstimjitter = expt.interstimjitter;
condnames = expt.conds;


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
    KbWaitForSpace; % mac version requires (-1)
    Screen('Flip',win);



%% display experiment text: SPEAK CONDITION
        pahandle = PsychPortAudio('Open', [], paMode_record, latencyClass, fs, nchannels);
        PsychPortAudio('GetAudioData', pahandle, bufsize);

        
    if ~isfield(expt.instruct)
        expt.instruct.readyspeak = 'Get ready to SPEAK'
        expt.instruct.readylisten = 'Get ready to LISTEN'
        expt.instruct.break = 'Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.'
        expt.instruct.thanks = 'Thank you!\n\n\n\nPlease wait.'
    end        
        
%    if strcmpi(language, 'French')
%       ready_speech = 'Préparez-vous à PARLER'
%       break_text = 'you may take ze bRake!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.'
%       thanks_text = 'Merci!\n\n\n\n Sil vous plait wait.'
%    else
%       ready_speech = 'Get ready to SPEAK'
%       break_text = 'Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.'
%       thanks_text = 'Thank you!\n\n\n\nPlease wait.'
%    end
        % display words
        allWords = zeros(1,ntrials);
        stimtimes_speak = zeros(1,ntrials);
        rectimes_speak = zeros(1,ntrials);
        stimtimes_listen = zeros(1,ntrials);
        rectimes_listen = zeros(1,ntrials);
        jitter = zeros(1,ntrials);

        WaitSecs(1);
        DrawFormattedText(win,ready_speech,'center','center',[255 255 255]);
        Screen('Flip',win);
        KbWaitForKey; % mac: (-1,2,2) and just regular KbWait
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
            if(usetrigs)
                trig2send = allWords(t) + trigoffset; 
                trigger_meg(di,trig2send,usetrigs);
            end
            
            if ~manualmode
                WaitSecs(stimdur);
            else
                tic;
                KbWait([],[],GetSecs+bufsize-interstimdur-interstimjitter); % -1 in first brackets
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
            breaktext = sprintf(break_text,t,ntrials);
        else
            breaktext = thanks_text;
        end
        DrawFormattedText(win,breaktext,'center','center',[255 255 255]);
        Screen('Flip',win);
        if b < nblocks
            KbWaitForKey; %(-1,2,2); % for key
        else
            KbWaitForSpace;% (-1);
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
    expt.name = 'cais';
    expt.snum = snum;
    expt.dataPath = dataPath;
    expt.conds = condnames;
    expt.words = words;
    expt.vowels = vowels;
    expt.ntrials = ntrials;
    expt.nblocks = nblocks;
    expt.nbtrials = nbtrials;
    expt.textsize = textsize;
    expt.instructtextsize = instructtextsize;
    expt.wordbank = wordbank;
    expt.stimdur = stimdur;
    expt.interstimdur = interstimdur;
    expt.interstimjitter = interstimjitter;
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
    expt.instruct = expt.instruct

    
    % save expt info
    save(fullfile(dataPath,'expt.mat'),'expt');
         

    Screen('CloseAll');
