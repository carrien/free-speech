function [errorTrialsIn, errorTrialsOut] = gen_dataVals_timeAdapt(dataPath)
%
% Largely copied from gen_dataVals_VOT but altered to address additional events for stops: 
% 1. beginning of closure
% 2. burst/end of closure
% 3. beginning of voicing
% 4. end of voicing (end of vowel) 
% 
% 
% Additionally some complications for fricatives not having all these events (or at least not in the same order) 
%
% RPK 11/2019

dbstop if error 

if nargin < 1 || isempty(dataPath), dataPath = cd; end

% set output files
trialInDir = 'trials';
trialOutDir = 'trials_signalOut'; 
savefileIn = fullfile(dataPath,sprintf('dataVals%s.mat',trialInDir(7:end)));
savefileOut = fullfile(dataPath,sprintf('dataVals%s.mat',trialOutDir(7:end)));

bSaveIn = savecheck(savefileIn);
bSaveOut = savecheck(savefileOut); 
if ~bSaveIn, return; end
if ~bSaveOut, return; end

% load expt files
load(fullfile(dataPath,'expt.mat'));
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
trialInPath = fullfile(dataPath,trialInDir); % e.g. trials; trials_default
trialOutPath = fullfile(dataPath,trialOutDir); 
[sortedTrialnums,sortedFilenames] = get_sortedTrials(trialInPath); % these should be the same for both in/out so only need to define once
% shortTracks = [];
dataVals = struct([]);


word = expt.allWords(1);
spokenWord = expt.listWords{1}; 
switch spokenWord 
    case {'capper','gapper'}
        max_events = 7;     % doesn't include aspiration. is OST status but not a user event        
    case {'sapper','zapper'}
        max_events = 6; 
    case {'sea','C','Z','czar','gar','cod','god'}
        max_events = 6; 
end
%% Trials in 
% extract tracks from each trial
e = 1; % error trial counter
errorTrialsIn = []; 
fprintf('Generating dataVals for signalIn... ')
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    load(fullfile(trialInPath,filename)); 
    
    if ~mod(i,25)
        fprintf('%d\n',trialnum); 
    else
        fprintf('%d ',trialnum); 
    end
    % get user-created events
    if exist('trialparams','var') ...
            && isfield(trialparams,'event_params') ...
            && ~isempty(trialparams.event_params)
        user_event_times = trialparams.event_params.user_event_times;
        user_event_names = trialparams.event_params.user_event_names; 
    else
        user_event_times = [];
        user_event_names = {}; 
        warning('No events for trial %d\n',trialnum); 
    end
    n_events = length(user_event_times);

    if trialparams.event_params.is_good_trial 
        % event times 
        v1Start_time = user_event_times(strcmp(user_event_names,'v1Start')); 
        cStart_time = user_event_times(strcmp(user_event_names,'cStart')); 
        cBurst_time = user_event_times(strcmp(user_event_names,'cBurst')); 
        v2Start_time = user_event_times(strcmp(user_event_names,'v2Start')); 
        pStart_time = user_event_times(strcmp(user_event_names,'pStart')); 
        erStart_time = user_event_times(strcmp(user_event_names,'erStart')); 
        erEnd_time = user_event_times(strcmp(user_event_names,'erEnd')); 

        % durations
        v1Dur = cStart_time - v1Start_time; 
        v2Dur = pStart_time - v2Start_time; 
        cDur = v2Start_time - cStart_time; 
        pDur = erStart_time - pStart_time; 
        erDur = erEnd_time - erStart_time; 

        bSpirant = 0; 
        if ~isempty(cBurst_time) % if you actually have a burst
            cClosureDur = cBurst_time - cStart_time; 
            vot = v2Start_time - cBurst_time;
            % the duration of interest
            manipTargetDur = vot; 
        else
            cClosureDur = cDur; 

            manipTargetDur = cDur; 
            if strcmp(word, 'gapper')
               bSpirant = 1;  
               vot = 0; 
            else
                vot = NaN; 
            end
        end

        if n_events > max_events
            warning('%d events found in trial %d (expected %d)',n_events,trialnum,max_events);
            fprintf('ignoring event %d\n',max_events+1:n_events)
        elseif n_events < max_events && bSpirant == 0
            warning('Only %d events found in trial %d (expected %d)',n_events,trialnum,max_events);
            fprintf('Check for empty values.\n')
            errorTrialsIn(e) = trialnum; 
            e = e+1; 
        end

        % find onset/offset indices for each track
        onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,v1Start_time); % f0
        offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,erEnd_time);
        onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,v2Start_time); % F1, F2
        offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,pStart_time);
        
%         if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
%         % use trial-specific amplitude threshold
%             onsetIndAmp = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
%         else % use wave_viewer_params default amplitude threshold
%             onsetIndAmp = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
%         end
%         if onsetIndAmp
%             onsetIndAmp = onsetIndAmp(1) + 1;
%         else
%             onsetIndAmp = 1; % set trial BAD here? reason: no onset found?
%         end

        onsetIndAmp = onsetIndf0; 
        offsetIndAmp = offsetIndf0; 
%         onset_time = sigmat.ampl_taxis(onsetIndAmp);

        % convert to dataVals struct
        dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
        dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
        dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
        dataVals(i).int = sigmat.ampl(onsetIndAmp:offsetIndAmp)';
        dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
        dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
        dataVals(i).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';
        
%         if ~isempty(v1Start_time) 
            dataVals(i).v1Start_time = v1Start_time; 
%         else
%             dataVals(i).v1Start_time = NaN; 
%         end
%         
%         if ~isempty(cStart_time)
            dataVals(i).cStart_time = cStart_time; 
%         else
%             dataVals(i).cStart_time = NaN; 
%         end
%                 
        if ~isempty(cBurst_time)
            dataVals(i).cBurst_time = cBurst_time; 
        else
            dataVals(i).cBurst_time = NaN; 
        end
%         
%         if ~isempty(v2Start_time)
            dataVals(i).v2Start_time = v2Start_time; 
%         else
%             dataVals(i).v2Start_time = NaN; 
%         end
%         
%         if ~isempty(pStart_time)
            dataVals(i).pStart_time = pStart_time; 
%         else
%             dataVals(i).pStart_time = NaN; 
%         end
%         
%         if ~isempty(erStart_time)
            dataVals(i).erStart_time = erStart_time; 
%         else
%             dataVals(i).erStart_time = NaN; 
%         end
%         
%         if ~isempty(erEnd_time)
            dataVals(i).erEnd_time = erEnd_time; 
%         else
%             dataVals(i).erEnd_time = NaN; 
%         end
%         
        dataVals(i).dur = pStart_time - v2Start_time; % for dataVals tracking. this is only the ash dur
        dataVals(i).totalDur = erEnd_time - v1Start_time;
        dataVals(i).wordDur = erEnd_time - cStart_time; 
        dataVals(i).v1Dur = v1Dur; % timeAdapt addition 
        dataVals(i).cDur = cDur; % timeAdapt addition 
        dataVals(i).cClosureDur = cClosureDur; % timeAdapt addition 
        dataVals(i).vot = vot; % timeAdapt addition
        dataVals(i).v2Dur = v2Dur; % timeAdapt addition 
        dataVals(i).pDur = pDur; % timeAdapt addition 
        dataVals(i).erDur = erDur; % timeAdapt addition 
        dataVals(i).manipTargetDur = manipTargetDur; 
        dataVals(i).spirantize = bSpirant;

        dataVals(i).word = word;
    %     dataVals(i).vowel = expt.allVowels(mod(trialnum, length(expt.allVowels)) + 1); % normally just trialnum (next two as well) 
    %     dataVals(i).color = expt.allColors(mod(trialnum, length(expt.allVowels)) + 1);
        dataVals(i).cond = expt.allConds(mod(trialnum, length(expt.allVowels)) + 1);
        dataVals(i).token = trialnum;
    
    else % bad trials get all NaNs
        dataVals(i).dur = NaN; 
        dataVals(i).totalDur = NaN;
        dataVals(i).wordDur = NaN; 
        dataVals(i).v1Dur = NaN; % timeAdapt addition 
        dataVals(i).cDur = NaN; % timeAdapt addition 
        dataVals(i).cClosureDur = NaN; % timeAdapt addition 
        dataVals(i).vot = NaN; % timeAdapt addition
        dataVals(i).v2Dur = NaN; % timeAdapt addition 
        dataVals(i).pDur = NaN; % timeAdapt addition 
        dataVals(i).erDur = NaN; % timeAdapt addition 
        dataVals(i).manipTargetDur = NaN; 
        dataVals(i).spirantize = NaN;

        dataVals(i).v1Start_time = NaN; 
        dataVals(i).cStart_time = NaN; 
        dataVals(i).cBurst_time = NaN; 
        dataVals(i).v2Start_time = NaN; 
        dataVals(i).pStart_time = NaN; 
        dataVals(i).erStart_time = NaN; 
        dataVals(i).erEnd_time = NaN; 

    
    end
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
end

save(savefileIn,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefileIn)


%% Trials out

% extract tracks from each trial
fprintf('Generating dataVals for signalOut... ')
e = 1; % error trial counter
errorTrialsOut = []; 
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    load(fullfile(trialOutPath,filename));
    
    if ~mod(i,25)
        fprintf('%d\n',trialnum); 
    else
        fprintf('%d ',trialnum); 
    end
    if trialparams.event_params.is_good_trial
        % get user-created events
        if exist('trialparams','var') ...
                && isfield(trialparams,'event_params') ...
                && ~isempty(trialparams.event_params)
            user_event_times = trialparams.event_params.user_event_times;
            user_event_names = trialparams.event_params.user_event_names; 
        else
            user_event_times = [];
            user_event_names = {}; 
            warning('No events for trial %d\n',trialnum); 
        end


        % event times 
        v1Start_time = user_event_times(strcmp(user_event_names,'v1Start')); 
        cStart_time = user_event_times(strcmp(user_event_names,'cStart')); 
        cBurst_time = user_event_times(strcmp(user_event_names,'cBurst')); 
        v2Start_time = user_event_times(strcmp(user_event_names,'v2Start')); 
        pStart_time = user_event_times(strcmp(user_event_names,'pStart')); 
        erStart_time = user_event_times(strcmp(user_event_names,'erStart')); 
        erEnd_time = user_event_times(strcmp(user_event_names,'erEnd')); 

        % durations
        v1Dur = cStart_time - v1Start_time; 
        v2Dur = pStart_time - v2Start_time; 
        cDur = v2Start_time - cStart_time; 
        pDur = erStart_time - pStart_time; 
        erDur = erEnd_time - erStart_time; 

        if ~isempty(cBurst_time) % if you actually have a burst
            cClosureDur = cBurst_time - cStart_time; 
            vot = v2Start_time - cBurst_time;
            % the duration of interest
            manipTargetDur = vot; 
        else
            cClosureDur = cDur; 
            vot = NaN;
            manipTargetDur = cDur; 
            if strcmp(word, 'gapper')
               bSpirant = 1;  
               vot = 0; 
            else
                vot = NaN; 
            end

        end
        n_events = length(user_event_times);
        if n_events > max_events 
            warning('%d events found in trial %d (expected %d)',n_events,trialnum,max_events);
            fprintf('ignoring event %d\n',max_events+1:n_events)
        elseif n_events < max_events && bSpirant == 0
            warning('Only %d events found in trial %d (expected %d)',n_events,trialnum,max_events);
            fprintf('Check for empty values.\n')
            errorTrialsOut(e) = trialnum; 
            e = e+1; 
        end

        % find onset/offset indices for each track
        onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,v1Start_time);
        offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,erEnd_time);
        onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,v1Start_time);
        offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,erEnd_time);

        onsetIndAmp = onsetIndf0; 
        offsetIndAmp = offsetIndf0; 

        % convert to dataVals struct
        dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
        dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
        dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
        dataVals(i).int = sigmat.ampl(onsetIndAmp:offsetIndAmp)';
        dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
        dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
        dataVals(i).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';
        
%         if ~isempty(v1Start_time) 
            dataVals(i).v1Start_time = v1Start_time; 
%         else
%             dataVals(i).v1Start_time = NaN; 
%         end
%         
%         if ~isempty(cStart_time)
            dataVals(i).cStart_time = cStart_time; 
%         else
%             dataVals(i).cStart_time = NaN; 
%         end
                
        if ~isempty(cBurst_time)
            dataVals(i).cBurst_time = cBurst_time; 
        else
            dataVals(i).cBurst_time = NaN; 
        end
        
%         if ~isempty(v2Start_time)
            dataVals(i).v2Start_time = v2Start_time; 
%         else
%             dataVals(i).v2Start_time = NaN; 
%         end
%         
%         if ~isempty(pStart_time)
            dataVals(i).pStart_time = pStart_time; 
%         else
%             dataVals(i).pStart_time = NaN; 
%         end
%         
%         if ~isempty(erStart_time)
            dataVals(i).erStart_time = erStart_time; 
%         else
%             dataVals(i).erStart_time = NaN; 
%         end
%         
%         if ~isempty(erEnd_time)
            dataVals(i).erEnd_time = erEnd_time; 
%         else
%             dataVals(i).erEnd_time = NaN; 
%         end
        
        dataVals(i).dur = pStart_time - v2Start_time; % for check_dataVals 
        dataVals(i).totalDur = erEnd_time - v1Start_time;
        dataVals(i).wordDur = erEnd_time - cStart_time; 
        dataVals(i).v1Dur = v1Dur; % timeAdapt addition 
        dataVals(i).cDur = cDur; % timeAdapt addition 
        dataVals(i).cClosureDur = cClosureDur; % timeAdapt addition 
        dataVals(i).vot = vot; % timeAdapt addition
        dataVals(i).v2Dur = v2Dur; % timeAdapt addition 
        dataVals(i).pDur = pDur; % timeAdapt addition 
        dataVals(i).erDur = erDur; % timeAdapt addition 
        dataVals(i).manipTargetDur = manipTargetDur; 

        dataVals(i).word = word;
    %     dataVals(i).vowel = expt.allVowels(mod(trialnum, length(expt.allVowels)) + 1); % normally just trialnum (next two as well) 
    %     dataVals(i).color = expt.allColors(mod(trialnum, length(expt.allVowels)) + 1);
        dataVals(i).cond = expt.allConds(mod(trialnum, length(expt.allVowels)) + 1);
        dataVals(i).token = trialnum;
    else
        dataVals(i).dur = NaN; 
        dataVals(i).totalDur = NaN;
        dataVals(i).wordDur = NaN; 
        dataVals(i).v1Dur = NaN; % timeAdapt addition 
        dataVals(i).cDur = NaN; % timeAdapt addition 
        dataVals(i).cClosureDur = NaN; % timeAdapt addition 
        dataVals(i).vot = NaN; % timeAdapt addition
        dataVals(i).v2Dur = NaN; % timeAdapt addition 
        dataVals(i).pDur = NaN; % timeAdapt addition 
        dataVals(i).erDur = NaN; % timeAdapt addition 
        dataVals(i).manipTargetDur = NaN; 
        dataVals(i).spirantize = NaN;
        
        dataVals(i).v1Start_time = NaN; 
        dataVals(i).cStart_time = NaN; 
        dataVals(i).cBurst_time = NaN; 
        dataVals(i).v2Start_time = NaN; 
        dataVals(i).pStart_time = NaN; 
        dataVals(i).erStart_time = NaN; 
        dataVals(i).erEnd_time = NaN; 
    end
        
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
end

save(savefileOut,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefileOut)

end
