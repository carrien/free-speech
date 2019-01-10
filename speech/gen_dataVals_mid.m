function [] = gen_dataVals_mid(dataPath,trialdir)
%GEN_DATAVALS_MID  Scrape subject trial files for data and save.
%   GEN_DATAVALS_MID(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%CN 11/2018

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end

max_events = 3; % three events: word onset, vowel midpoint, word offset
min_events = 3;
onsetEventInd = 1;
midEventInd = 2; midwinsize_s = .05;
offsetEventInd = 3;

% set output files
savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
bSave = savecheck(savefile);
if ~bSave, return; end
savefileMid = fullfile(dataPath,sprintf('dataValsMid%s.mat',trialdir(7:end)));
bSave = savecheck(savefileMid);
if ~bSave, return; end

% load expt files
load(fullfile(dataPath,'expt.mat'));
%if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
%    load(fullfile(dataPath,'wave_viewer_params.mat'));
%end
trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
[sortedTrialnums,sortedFilenames] = get_sortedTrials(trialPath);
shortTracks = [];
dataVals = struct([]);
dataValsMid = struct([]);

% extract tracks from each trial
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    load(fullfile(trialPath,filename));
    
    %% find events
    % get user-created events
    if exist('trialparams','var') ...
            && isfield(trialparams,'event_params') ...
            && ~isempty(trialparams.event_params)
        user_event_times = sort(trialparams.event_params.user_event_times);
    else
        user_event_times = [];
    end
    
    % match events to onset, midpoint, and offset
    n_events = length(user_event_times);    
    if n_events > max_events
        warning('%d events found in trial %d (expected %d or fewer)',n_events,trialnum,max_events);
        fprintf('ignoring event %d\n',max_events+1:n_events)
    elseif n_events < min_events
        if ~trialparams.event_params.is_good_trial
            continue; % if bad trial, don't throw error
        else
            error('Only %d events found in trial %d (expected at least %d)',n_events,trialnum,min_events);
        end
    end
    
    % find word onset = time of first user-created event
    onset_time = user_event_times(onsetEventInd);
    onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,onset_time);
    onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,onset_time);
    onsetIndAmp = get_index_at_time(sigmat.ampl_taxis,onset_time);
    
    % find vowel midpoint = time of second user-created event
    vowelMid_time = user_event_times(midEventInd);

    vowelMidStartIndfx = get_index_at_time(sigmat.ftrack_taxis,vowelMid_time-midwinsize_s/2);
    vowelMidEndIndfx = get_index_at_time(sigmat.ftrack_taxis,vowelMid_time+midwinsize_s/2);
    
    vowelMidStartIndf0 = get_index_at_time(sigmat.pitch_taxis,vowelMid_time-midwinsize_s/2);
    vowelMidEndIndf0 = get_index_at_time(sigmat.pitch_taxis,vowelMid_time+midwinsize_s/2);
    
    vowelMidStartIndAmp = get_index_at_time(sigmat.ampl_taxis,vowelMid_time-midwinsize_s/2);
    vowelMidEndIndAmp = get_index_at_time(sigmat.ampl_taxis,vowelMid_time+midwinsize_s/2);
    
    % find offset = time of user-created offset event
    offset_time = user_event_times(offsetEventInd);
    offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offset_time);
    offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offset_time);
    offsetIndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time);
    
    %% convert to dataVals struct
    dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
    dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
    dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
    dataVals(i).int = sigmat.ampl(onsetIndAmp:offsetIndAmp)';
    dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
    dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
    dataVals(i).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';
    dataVals(i).dur = offset_time - onset_time;
    dataVals(i).word = expt.allWords(trialnum);
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
    
    %% convert to dataValsMid struct
    fieldns = fieldnames(dataVals);
    for f=1:length(fieldns)
        dataValsMid(i).(fieldns{f}) = dataVals(i).(fieldns{f});
    end
    dataValsMid(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
    dataValsMid(i).f1 = sigmat.ftrack(1,vowelMidStartIndfx:vowelMidEndIndfx)';
    dataValsMid(i).f2 = sigmat.ftrack(2,vowelMidStartIndfx:vowelMidEndIndfx)';
    dataValsMid(i).int = sigmat.ampl(vowelMidStartIndAmp:vowelMidEndIndAmp)';
    dataValsMid(i).pitch_taxis = sigmat.pitch_taxis(vowelMidStartIndf0:vowelMidEndIndf0)';
    dataValsMid(i).ftrack_taxis = sigmat.ftrack_taxis(vowelMidStartIndfx:vowelMidEndIndfx)';
    dataValsMid(i).ampl_taxis = sigmat.ampl_taxis(vowelMidStartIndAmp:vowelMidEndIndAmp)';

end

if ~isempty(shortTracks)
    shortTracks = unique(shortTracks);
    warning('Short track list: %s',num2str(shortTracks));
end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile)

save(savefileMid,'dataValsMid');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefileMid)

end
