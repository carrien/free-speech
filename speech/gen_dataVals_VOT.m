function [] = gen_dataVals_VOT(dataPath,trialdir)
%GEN_DATAVALS_VOT  Scrape subject trial files for data and save.
%   GEN_DATAVALS_VOT(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%CN 5/2018

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end

max_events = 3; % three events for VOT study: word onset, voice onset, word offset

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
sortedTrials = get_sortedTrials(trialPath);
shortTracks = [];
dataVals = struct([]);

% extract tracks from each trial
for i = 1:length(sortedTrials)
    trialnum = sortedTrials(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename));
    
    word = expt.allWords(trialnum);
    if isfield(expt,'allColors') 
        color = expt.allColors(trialnum);
    else
        color = [];
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
        % find time of first user-created event
        onset_time = user_event_times(1);
        onsetIndAmp = get_index_at_time(sigmat.ampl_taxis,onset_time);
    else
        % use amplitude threshold to find suprathreshold indices
        if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
            % use trial-specific amplitude threshold
            amplInds = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
        else % use wave_viewer_params default amplitude threshold
            amplInds = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
        end
        % set onset to first suprathreshold index
        if amplInds
            onsetIndAmp = amplInds(1) + 1;
        else
            onsetIndAmp = 1; % set trial BAD here? reason: no onset found?
        end
        onset_time = sigmat.ampl_taxis(onsetIndAmp);
    end
    
    % find vowel onset
    if any(strncmp(color,{'p' 't' 'k' 'b' 'd' 'g'},1))
        % find time of second user-created event
        if n_events > 1 && user_event_times(1) ~= user_event_times(2)
            vowelOnset_time = user_event_times(2);
            vowelOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,vowelOnset_time);
            offsetEventInd = 3;
        else
            % check if bad trial
            if ~trialparams.event_params.is_good_trial
                % if bad trial, don't throw error; use word onset as vowel onset
                vowelOnset_time = onset_time;
                vowelOnsetIndAmp = onsetIndAmp;
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
    else
        % use word onset as vowel onset
        vowelOnset_time = onset_time;
        vowelOnsetIndAmp = onsetIndAmp;
        offsetEventInd = 2;
    end
    
    % find offset
    if n_events >= offsetEventInd && user_event_times(offsetEventInd) ~= user_event_times(offsetEventInd-1)
        % find time of user-created offset event
        offset_time = user_event_times(offsetEventInd);
        offsetIndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time);
    else
        % find first sub-threshold amplitude value after onset
        if exist('trialparams','var') && ~isempty(trialparams.sigproc_params) 
            % use trial-specific amplitude threshold
            amplInds = find(sigmat.ampl(vowelOnsetIndAmp:end) < trialparams.sigproc_params.ampl_thresh4voicing);
        else % use wave_viewer_params default amplitude threshold
            amplInds = find(sigmat.ampl(vowelOnsetIndAmp:end) < sigproc_params.ampl_thresh4voicing);
        end
        % set offset to first subthreshold index after word/voice onset
        if amplInds
            offsetIndAmp = amplInds(1) - 1 + vowelOnsetIndAmp; % correct indexing
        else
            offsetIndAmp = length(sigmat.ampl); % use last index if no offset found
        end
        offset_time = sigmat.ampl_taxis(offsetIndAmp); % or -1?
    end

    % find onset/offset indices for each track
    onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,vowelOnset_time);
    offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offset_time);
    onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,vowelOnset_time);
    offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offset_time);
    
    % convert to dataVals struct
    dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
    dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
    dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
    dataVals(i).int = sigmat.ampl(onsetIndAmp:offsetIndAmp)';
    dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
    dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
    dataVals(i).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';
    dataVals(i).dur = offset_time - onset_time;
    dataVals(i).vot = vowelOnset_time - onset_time;
    dataVals(i).word = word;
    dataVals(i).vowel = expt.allVowels(trialnum);
    dataVals(i).color = color;
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
fprintf('%d trials saved in %s.\n',length(sortedTrials),savefile)

end
