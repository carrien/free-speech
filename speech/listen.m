function [listen] = listen(snum,dataPath,usetrigs,practicemode,manualmode, expt, data)
Screen('Preference', 'SkipSyncTests', 1); % added to work on Sarah's office Mac

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


    % defining terms passed in from speak condition
expt
    
ntrials = expt.ntrials;
textsize =  expt.textsize;
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
allWords = expt.allWords
jitter = expt.jitter
instruct = expt.instruct    
    
 
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
    KbWaitForSpace;% (-1); %-1 required on a mac so it finds the keyboard; -1 means check all
    Screen('Flip',win);





    %% display experiment text: LISTEN CONDITION
    pahandle = PsychPortAudio('Open', [], paMode_playback, latencyClass, fs, nchannels);

    if strcmpi(language, 'French')
        ready_speech = 'Préparez-vous à ÉCOUTER'
       break_text = 'you may take ze bRake!\n\n%d of %d trials done.\n\n\n\nPress ze button to continue.'
       thanks_text = 'Merci!\n\n\n\n Sil vous plait wait.'
    else
        ready_speech = 'Get ready to LISTEN'
       break_text = 'Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.'
       thanks_text = 'Thank you!\n\n\n\nPlease wait.'
    end    
    
    WaitSecs(1);
    DrawFormattedText(win,ready_speech,'center','center',[255 255 255]);
    Screen('Flip',win);
    KbWaitForKey;%([],1); % for key
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
%            trig2send = allWords(t)+length(words) + trigoffset; % done
%            to separate phases 
%            trigger_meg(di,trig2send,usetrigs);

            if ~manualmode
                WaitSecs(stimdur);
            else
                stimdurs(t) = toc;
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
            breaktext = sprintf(break_text,t,ntrials);
        else
            breaktext = thanks_text;
        end
        DrawFormattedText(win,breaktext,'center','center',[255 255 255]);
        Screen('Flip',win);
        if b < nblocks
            KbWaitForKey;%([],1); %for key
        else
            KbWaitForSpace; %(-1);
        end
        Screen('Flip',win);
    end    
    
Screen('CloseAll');
