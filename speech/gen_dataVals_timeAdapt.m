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

max_events = 5; 
% Stops will have five events: beginning of first vowel; closure; burst; VOT; end of second vowel 
% Fricatives will have four events: beginning of first vowel; closure; beginning of second vowel; end of second vowel

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
        vowel1OnsetTime = user_event_times(1);
        vowel1OnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowel1OnsetTime);
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
            vowel1OnsetIndAmp = amplInds(1) + 1;
        else
            vowel1OnsetIndAmp = 1; % set trial BAD here? reason: no onset found?
        end
        vowel1OnsetTime = sigmat.ampl_taxis(vowel1OnsetIndAmp);
    end
    
    % find vowel onset: diverges from dataVals_VOT here. assumes 5 events for stops and 4 for fricatives
    if strcmp(condWord,'car') || strcmp(condWord, 'gar')
        % find time of second user-created event
        if n_events > 1 && user_event_times(1) ~= user_event_times(2) && bPrecheck == 0
            closureTime = user_event_times(2); 
            closureIndAmp = get_index_at_time(sigmat.ampl_taxis,closureTime);
            
            burstTime = user_event_times(3);
            burstIndAmp = get_index_at_time(sigmat.ampl_taxis,burstTime);
            
            vowel2OnsetTime = user_event_times(4); 
            vowelOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowel2OnsetTime);
            
            vowel2OffsetTime = user_event_times(5); 
            vowel2OffsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowel2OffsetTime);
            
            offsetEventInd = 5;
            
            % Calculations for stop trials
            v1Dur = closureTime - vowel1OnsetTime; 
            closureDur = burstTime - closureTime; 
            vot = vowel2OnsetTime - burstTime; 
            v2Dur = vowel2OffsetTime - vowel2OnsetTime; 
            
        else
            % check if bad trial
            if ~trialparams.event_params.is_good_trial
                % if bad trial, don't throw error; use word onset as vowel onset
                burstTime = vowel1OnsetTime;
                burstIndAmp = vowel1OnsetIndAmp;
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
            closureTime = user_event_times(2); 
            closureIndAmp = get_index_at_time(sigmat.ampl_taxis,closureTime);
           
            burstTime = 0; % Doing this so it doesn't error or give you a holdover value
            burstIndAmp = 0; 
            
            vowel2OnsetTime = user_event_times(3);
            vowelOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowel2OnsetTime);
            
            vowel2OffsetTime = user_event_times(4);
            vowelOffsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowel2OffsetTime);
            offsetEventInd = 4;
            
            % Fricative stricture duration
            v1Dur = closureTime - vowel1OnsetTime; 
            closureDur = vowel2OnsetTime - closureTime; 
            v2Dur = vowel2OffsetTime - vowel2OnsetTime; 
            vot = NaN; 
            
        else
            % check if bad trial
            if ~trialparams.event_params.is_good_trial
                % if bad trial, don't throw error; use word onset as vowel onset
                burstTime = vowel1OnsetTime;
                burstIndAmp = vowel1OnsetIndAmp;
                offsetEventInd = 2;
                closureDur = NaN; 
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
        
    else % For some reason you have some other word
        warning('You have used a word other than car, gar, saw, or czar'); 
        % use word onset as vowel onset
        burstTime = vowel1OnsetTime;
        burstIndAmp = vowel1OnsetIndAmp;
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
    onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,vowel2OnsetTime);
    offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offsetTime);
    onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,vowel2OnsetTime);
    offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offsetTime);
    
    % convert to dataVals struct
    dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
    dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
    dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
    dataVals(i).int = sigmat.ampl(vowel1OnsetIndAmp:offsetIndAmp)';
    dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
    dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
    dataVals(i).ampl_taxis = sigmat.ampl_taxis(vowel1OnsetIndAmp:offsetIndAmp)';
    dataVals(i).totalDur = offsetTime - vowel1OnsetTime;
    dataVals(i).closureDur = closureDur; % timeAdapt addition
    dataVals(i).vot = vot; % timeAdapt edit
    dataVals(i).v1Dur = v1Dur; % timeAdapt addition 
    dataVals(i).v2Dur = v2Dur; 
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
