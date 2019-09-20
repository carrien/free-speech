function [] = gen_dataVals_timeAdapt(dataPath,trialdir)
%GEN_DATAVALS_VOT  Scrape subject trial files for data and save.
%   GEN_DATAVALS_VOT(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
% Largely copied from gen_dataVals_VOT but altered to address additional events for stops: 
% 1. beginning of closure
% 2. burst/end of closure
% 3. beginning of voicing
% 4. end of voicing (end of vowel) 
% 
% 2-1 = closure duration
% 3-2 = VOT
% 4-3 = vowel duration 
% 
% Additionally some complications for fricatives not having all these events (or at least not in the same order) 
%
%CN 5/2018
% RPK 9/2019

dbstop if error 

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end

max_events = 4; % three events for VOT study: word onset, voice onset, word offset

% set output file
savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
bSave = savecheck(savefile);
if ~bSave, return; end

% load expt files
load(fullfile(dataPath,'expt.mat'));
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
[sortedTrialnums,sortedFilenames] = get_sortedTrials(trialPath);
shortTracks = [];
dataVals = struct([]);

% extract tracks from each trial
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    load(fullfile(trialPath,filename));
    
    word = expt.allWords(trialnum);
    if isfield(expt,'listWords') 
        condWord = expt.listWords{trialnum};
    else
        condWord = [];
    end
    
    % get user-created events
    if exist('trialparams','var') ...
            && isfield(trialparams,'event_params') ...
            && ~isempty(trialparams.event_params)
        user_event_times = sort(trialparams.event_params.user_event_times);
    else
        user_event_times = [];
    end
    n_events = length(user_event_times);
    if n_events > max_events
        warning('%d events found in trial %d (expected %d or fewer)',n_events,trialnum,max_events);
        fprintf('ignoring event %d\n',max_events+1:n_events)
    end
    
    % find word onset
    if n_events
        % find time of first user-created event (beginning of word/consonant stricture) 
        wordOnsetTime = user_event_times(1);
        wordOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,wordOnsetTime);
    else % RK not sure what to do with this else here. There needs to be an event... 
        % use amplitude threshold to find suprathreshold indices
        if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
            % use trial-specific amplitude threshold
            amplInds = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
        else % use wave_viewer_params default amplitude threshold
            amplInds = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
        end
        % set onset to first suprathreshold index
        if amplInds
            wordOnsetIndAmp = amplInds(1) + 1;
        else
            wordOnsetIndAmp = 1; % set trial BAD here? reason: no onset found?
        end
        wordOnsetTime = sigmat.ampl_taxis(wordOnsetIndAmp);
    end
    
    % find vowel onset: diverges from dataVals_VOT here. assumes 4 events for stops and 3 for fricatives
    if strcmp(condWord,'car') || strcmp(condWord, 'gar')
        % find time of second user-created event
        if n_events > 1 && user_event_times(1) ~= user_event_times(2)
            burstTime = user_event_times(2);
            burstIndAmp = get_index_at_time(sigmat.ampl_taxis,burstTime);
            
            vowelOnsetTime = user_event_times(3); 
            vowelOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowelOnsetTime); 
            offsetEventInd = 4;
            
            % Stop closure duration
            closureDur = burstTime - wordOnsetTime; 
            vot = vowelOnsetTime - burstTime; 
        else
            % check if bad trial
            if ~trialparams.event_params.is_good_trial
                % if bad trial, don't throw error; use word onset as vowel onset
                burstTime = wordOnsetTime;
                burstIndAmp = wordOnsetIndAmp;
                closureDur = 18; 
                offsetEventInd = 2;
            else
                % if good trial, error
                if n_events
                    n_event_str = 'only 1 event';
                else
                    n_event_str = 'no events';
                end
                error('Voice onset event not set for trial %d (%s found).',trialnum,n_event_str)
            end
        end
    elseif strcmp(condWord,'czar') || strcmp(condWord, 'saw') % the fricatives
        if n_events > 1 && user_event_times(1) ~= user_event_times(2)
            burstTime = 0; % Doing this so it doesn't error or give you a holdover value
            burstIndAmp = 0; 
            
            vowelOnsetTime = user_event_times(2);
            vowelOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowelOnsetTime);
            offsetEventInd = 3;
            
            % Fricative stricture duration
            closureDur = vowelOnsetTime - wordOnsetTime; 
            vot = NaN; 
            
        else
            % check if bad trial
            if ~trialparams.event_params.is_good_trial
                % if bad trial, don't throw error; use word onset as vowel onset
                burstTime = wordOnsetTime;
                burstIndAmp = wordOnsetIndAmp;
                offsetEventInd = 2;
                closureDur = 5; 
            else
                % if good trial, error
                if n_events
                    n_event_str = 'only 1 event';
                else
                    n_event_str = 'no events';
                end
                error('Voice onset event not set for trial %d (%s found).',trialnum,n_event_str)
            end
        end
        
    else
        % use word onset as vowel onset
        burstTime = wordOnsetTime;
        burstIndAmp = wordOnsetIndAmp;
        offsetEventInd = 2;
    end
    
    % find offset
    if n_events >= offsetEventInd && user_event_times(offsetEventInd) ~= user_event_times(offsetEventInd-1)
        % find time of user-created offset event
        offsetTime = user_event_times(offsetEventInd);
        offsetIndAmp = get_index_at_time(sigmat.ampl_taxis,offsetTime);
    else
        % find first sub-threshold amplitude value after onset
        if exist('trialparams','var') && ~isempty(trialparams.sigproc_params) 
            % use trial-specific amplitude threshold
            amplInds = find(sigmat.ampl(burstIndAmp:end) < trialparams.sigproc_params.ampl_thresh4voicing);
        else % use wave_viewer_params default amplitude threshold
            amplInds = find(sigmat.ampl(burstIndAmp:end) < sigproc_params.ampl_thresh4voicing);
        end
        % set offset to first subthreshold index after word/voice onset
        if amplInds
            offsetIndAmp = amplInds(1) - 1 + burstIndAmp; % correct indexing
        else
            offsetIndAmp = length(sigmat.ampl); % use last index if no offset found
        end
        offsetTime = sigmat.ampl_taxis(offsetIndAmp); % or -1?
    end

    % find onset/offset indices for each track
    onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,vowelOnsetTime);
    offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offsetTime);
    onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,vowelOnsetTime);
    offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offsetTime);
    
    % convert to dataVals struct
    dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
    dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
    dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
    dataVals(i).int = sigmat.ampl(wordOnsetIndAmp:offsetIndAmp)';
    dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
    dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
    dataVals(i).ampl_taxis = sigmat.ampl_taxis(wordOnsetIndAmp:offsetIndAmp)';
    dataVals(i).dur = offsetTime - wordOnsetTime;
    dataVals(i).closureDur = closureDur; % timeAdapt addition
    dataVals(i).vot = vot; % timeAdapt edit
    dataVals(i).vowelDur = offsetTime - vowelOnsetTime; % timeAdapt addition 
    dataVals(i).word = word;
    dataVals(i).vowel = expt.allVowels(trialnum);
    dataVals(i).color = expt.allColors(trialnum);
    dataVals(i).cond = expt.allConds(trialnum);
    dataVals(i).token = trialnum;
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
    
    % warn about short tracks
    if ~dataVals(i).bExcl && sum(~isnan(dataVals(i).f0)) < 20
        shortTracks = [shortTracks dataVals(i).token];
        warning('Short pitch track: trial %d',dataVals(i).token);
    end
    if ~dataVals(i).bExcl && sum(~isnan(dataVals(i).f1)) < 20
        shortTracks = [shortTracks dataVals(i).token];
        warning('Short formant track: trial %d',dataVals(i).token);
    end

end

if ~isempty(shortTracks)
    shortTracks = unique(shortTracks);
    warning('Short track list: %s',num2str(shortTracks));
end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile)

end
