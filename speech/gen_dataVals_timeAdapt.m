function [] = gen_dataVals_timeAdapt(dataPath)
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
% RPK 11/2019

dbstop if error 

if nargin < 1 || isempty(dataPath), dataPath = cd; end




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
% shortTracks = [];
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
    
    switch condWord
        case {'capper','gapper'}
            max_events = 7;     % doesn't include aspiration. is OST status but not a user event        
        case {'sapper','zapper'}
            max_events = 6; 
        case {'sea','C','Z','czar','gar','cod','god'}
            max_events = 6; 
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
    if n_events > max_events
        warning('%d events found in trial %d (expected %d)',n_events,trialnum,max_events);
        fprintf('ignoring event %d\n',max_events+1:n_events)
    elseif n_events < max_events
        warning('Only %d events found in trial %d (expected %d)',n_events,trialnum,max_events);
        fprintf('Check for empty values.\n')
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
    end
    
    % find onset/offset indices for each track
    onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,v1Start_time);
    offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,erEnd_time);
    onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,v1Start_time);
    offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,erEnd_time);
    
    % convert to dataVals struct
    dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';
    dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';
    dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';
%     dataVals(i).int = sigmat.ampl(vowel1OnsetIndAmp:offsetIndAmp)';
    dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';
    dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';
%     dataVals(i).ampl_taxis = sigmat.ampl_taxis(vowel1OnsetIndAmp:offsetIndAmp)';
    
    dataVals(i).totalDur = erEnd_time - v1Start_time;
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
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
    
%     % warn about short tracks
%     if ~dataVals(i).bExcl && sum(~isnan(dataVals(i).f0)) < 20
%         shortTracks = [shortTracks dataVals(i).token];
%         warning('Short pitch track: trial %d',dataVals(i).token);
%     end
%     if ~dataVals(i).bExcl && sum(~isnan(dataVals(i).f1)) < 20
%         shortTracks = [shortTracks dataVals(i).token];
%         warning('Short formant track: trial %d',dataVals(i).token);
%     end

end

% if ~isempty(shortTracks)
%     shortTracks = unique(shortTracks);
%     warning('Short track list: %s',num2str(shortTracks));
% end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile)

end
