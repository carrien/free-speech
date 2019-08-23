function [] = gen_dataVals_sAdapt(dataPath,trialdir)
%GEN_DATAVALS_VOT  Scrape subject trial files for data and save.
%   GEN_DATAVALS_VOT(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%CN 5/2018

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end

max_events = 2; % two events: fricative onset and offset

% add path to spectral centering
try
    temp = which('run_sAdapt_all');
    expPath = fileparts(temp);
    addpath(fullfile(expPath,'fromHiroki'))
catch
    error('No path to s_adapt experiment found. Please add current-studies repo to file path.')
end

% set output file
savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
bSave = savecheck(savefile);
if ~bSave, return; end

% load expt files
load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,'data.mat'));
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
    
    % get user-created events
    if exist('trialparams','var') ...
            && isfield(trialparams,'event_params') ...
            && ~isempty(trialparams.event_params) ...
            && trialparams.event_params.is_good_trial
        user_event_times = sort(trialparams.event_params.user_event_times);
    else
        user_event_times = [];
    end
    n_events = length(user_event_times);
    if n_events ~= max_events
        warning('%d events found in trial %d (expected %d)',n_events,trialnum,max_events);
        fprintf('ignoring event %d\n',max_events+1:n_events)
    end
    
    % find fricative onset
    if n_events == max_events
        % find time of first user-created event
        onset_time = user_event_times(1);
        onsetIndAmp = get_index_at_time(sigmat.ampl_taxis,onset_time);
        onsetIndSig = round(onset_time*trialparams.sigproc_params.fs);
    
        % find time of user-created offset event
        offset_time = user_event_times(2);
        offsetIndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time);
        offsetIndSig = round(offset_time*trialparams.sigproc_params.fs);

        % find onset/offset indices for each track
        onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,onset_time);
        offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offset_time);
        onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,onset_time);
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
        dataVals(i).word = word;
        dataVals(i).sibilant = expt.allSibilants(trialnum);
        dataVals(i).color = expt.allColors(trialnum);
        dataVals(i).cond = expt.allConds(trialnum);
        dataVals(i).token = trialnum;
        dataVals(i).scIn = koenig2013_sc(data(i).signalIn(onsetIndSig:offsetIndSig),trialparams.sigproc_params.fs);
        dataVals(i).scOut = koenig2013_sc(data(i).signalOut(onsetIndSig:offsetIndSig),trialparams.sigproc_params.fs);        
    end   
    
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
    
    % warn about short tracks
    if ~dataVals(i).bExcl 
        if sum(~isnan(dataVals(i).f0)) < 20
            shortTracks = [shortTracks dataVals(i).token];
            warning('Short pitch track: trial %d',dataVals(i).token);
        elseif ~dataVals(i).bExcl && sum(~isnan(dataVals(i).f1)) < 20
            shortTracks = [shortTracks dataVals(i).token];
            warning('Short formant track: trial %d',dataVals(i).token);
        end
    end

end

if ~isempty(shortTracks)
    shortTracks = unique(shortTracks);
    warning('Short track list: %s',num2str(shortTracks));
end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile)

end
