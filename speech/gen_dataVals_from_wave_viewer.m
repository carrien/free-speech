function [] = gen_dataVals_from_wave_viewer(dataPath,trialdir,bSaveCheck, mode)
%GEN_DATAVALS  Scrape subject trial files for data and save.
%   GEN_DATAVALS(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%CN 3/2010

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 4 || isempty(mode)
    mode = 1;
elseif ~any(mode == [1 2 3])
    error('The input variable mode must be 1, 2, 3, or empty.')
end
% EXPLAINING MODES:
% MODE 1 is the default and traditional use case. Each trial has one
% segment which is tracked. This segment is one of:
%   * [If no user events] The period of the first contiguous formant track
%   * [If 2+ user events] The period between the first and last user events
%   * [If 1 user event] The period between the only user event and:
%         ** the end of the current contiguous formant track
%         ** when the amplitude goes below the default amplitude threshold
% MODE 2 also tracks one segment. It tracks the first vowel, when the trial
%   was passed through the Montreal Forced Aligner (MFA). The tracked
%   segment is:
%   * the period between the first user event whose name is the
%       same as one of the mfa_vowels, and the next user event.
%   * the period between the first user event whose name is the same as
%       one of the mfa_vowels, and the end of the current formant track
%   * the period between the first user event whose name is the same as
%       one of the mfa_vowels, and when the amplitude goes below the
%       default amplitude threshold
% MODE 3 tracks multiple segments. It tracks the period between any two
%   consecutive user events. It saves dataVals as a cell array, where each
%   cell is the data from one segment.
%
%   For example, a trial with 4 user events will have a 3-cell array in
%   dataVals, representing the periods between user events 1-2, 2-3, & 3-4.


mfa_vowels = {'IY' 'IH' 'EH' 'AE' 'AA' 'AH' 'OW' 'UW' 'EY' 'UH'};

savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if ~bSave, return; end

load(fullfile(dataPath,'expt.mat'), 'expt');
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'), 'sigproc_params');
else
    sigproc_params = get_sigproc_defaults;
end

trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
W = what(trialPath);
matFiles = [W.mat];

% Strip off '.mat' and sort
filenums = zeros(1,length(matFiles));
for i = 1:length(matFiles)
    [~, name] = fileparts(matFiles{i});
    filenums(i) = str2double(name);
end
sortedfiles = sort(filenums);
shortTracks = [];
tooManyEvents = [];

dataVals = struct([]);

%use number of user events in first trial to evaluate if settings are reasonable
filename = sprintf('%d.mat',sortedfiles(1));
load(fullfile(trialPath,filename), 'trialparams');
numUserEventsInTrial1 = length(trialparams.event_params.user_event_times);

if numUserEventsInTrial1 <= 2 && mode == 3
    error(['mode is set to track multiple segments, but fewer than 3 user events were detected in first trial. ' ...
            'These settings are incompatible.']);
end

for i = 1:length(sortedfiles)
    trialnum = sortedfiles(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename), 'sigmat', 'trialparams');
    
    numUserEvents = length(trialparams.event_params.user_event_times);
    
    if mode == 3
        nSegments = numUserEvents - 1;
    else
        nSegments = 1;
    end
    
    for v = 1:nSegments
        % skip bad trials, except for adding metadata, and making cell
        % structure if mode == 3
        if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params) ...
                && isfield(trialparams.event_params, 'is_good_trial') && ~trialparams.event_params.is_good_trial
            dataVals(i).word = expt.allWords(trialnum);
            dataVals(i).vowel = expt.allVowels(trialnum);
            if isfield(expt,'allColors')
                dataVals(i).color = expt.allColors(trialnum);
            end
            dataVals(i).cond = expt.allConds(trialnum);
            dataVals(i).token = trialnum;
            dataVals(i).bExcl = 1;
            
            if mode == 3
                dataVals = makeEmptyCells(dataVals, i, nSegments, sigmat);
            end
        else
            % find onset
            if numUserEvents
                if mode == 2
                    onset_ix = find(ismember(trialparams.event_params.user_event_names, mfa_vowels)); %the first uev with a "vowel" name
                    onset_time = trialparams.event_params.user_event_times(onset_ix);
                elseif isfield(expt,'name') && contains(expt.name, {'brut', 'port' 'brutGerman' 'portGerman'}, 'IgnoreCase', true)
                    uevnames = trialparams.event_params.user_event_names;
                    vow = expt.listVowels{trialnum};
                    if strcmpi(vow,'oe')
                        vow = 'ah';
                    end
                    
                    if (strcmpi(expt.listWords{trialnum}, 'hais') || strcmpi(expt.listWords{trialnum},'fait'))
                        vow = 'ey';
                    elseif strcmpi(expt.listWords{trialnum},'oeuf')
                        vow = 'ah';
                    elseif strcmpi(expt.listWords{trialnum},'neuf')
                        vow = 'uw';
                    end
                    onset_name = [upper(vow) 'Start'];
                    uevind = find(contains(uevnames,onset_name));
                    if size(uevind,2) > 1 % added for German; if something goes wrong check here.
                        uevind = uevind(1);
                    end
                    if isempty(uevind)
                        if (strcmpi(expt.listWords{trialnum},'oeuf') || strcmpi(expt.listWords{trialnum},'neuf'))
                            onset_name='spnStart'; % Sarah needs to figure out why this is happening and fix it
                            uevind = find(contains(uevnames,onset_name));
                        end
                    end
                    
                    if exist('uevind','var')
                        onset_time = trialparams.event_params.user_event_times(uevind);
                    end
                    sprintf('trialnumber %d, word %s',trialnum, expt.listWords{trialnum})
                else
                    % find time of user-created onset event
                    user_event_times = sort(trialparams.event_params.user_event_times);
                    onset_time = user_event_times(v);
                end
                timediff = sigmat.ampl_taxis - onset_time;
                [~, onsetIndAmp] = min(abs(timediff));
            else
                % use amplitude threshold to find onset index. This won't work for experiments with multiple words in a trial (SimOn)
                if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                    % use trial-specific amplitude threshold
                    onsetIndAmp = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
                else % use wave_viewer_params default amplitude threshold
                    onsetIndAmp = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
                end
                if onsetIndAmp, onsetIndAmp = onsetIndAmp(1) + 1;
                else, onsetIndAmp = 1; % set trial BAD here? reason: no onset found?
                end
                onset_time = sigmat.ampl_taxis(onsetIndAmp);
            end
            
            % find offset
            if mode == 2
                if onset_ix < length(trialparams.event_params.user_event_times)
                    offset_time = trialparams.event_params.user_event_times(onset_ix + 1);
                else
                    offset_time = onset_time + 0.0001; % TODO change this, if it gets retained in this fx
                end
                timediff = sigmat.ampl_taxis - offset_time;
                [~, offsetIndAmp] = min(abs(timediff));
            elseif exist('user_event_times','var') && length(user_event_times) > (v) && user_event_times(v) ~= user_event_times(v+1)
                % find time of user-created offset event
                offset_time = user_event_times(v+1);
                timediff = sigmat.ampl_taxis - offset_time;
                [~, offsetIndAmp] = min(abs(timediff));
            elseif exist('uevind','var')
                offind = uevind+1;
                offset_time = trialparams.event_params.user_event_times(offind);
                timediff = sigmat.ampl_taxis - offset_time;
                [~, offsetIndAmp] = min(abs(timediff));
                
            else
                % find first sub-threshold amplitude value after onset
                if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                    % use trial-specific amplitude threshold
                    offsetIndAmp = find(sigmat.ampl(onsetIndAmp:end) < trialparams.sigproc_params.ampl_thresh4voicing);
                else % use wave_viewer_params default amplitude threshold
                    offsetIndAmp = find(sigmat.ampl(onsetIndAmp:end) < sigproc_params.ampl_thresh4voicing);
                end
                if offsetIndAmp
                    offsetIndAmp = offsetIndAmp(1) + onsetIndAmp-1; % correct indexing
                else
                    offsetIndAmp = length(sigmat.ampl); % use last index if no offset found
                end
                offset_time = sigmat.ampl_taxis(offsetIndAmp); % or -1?
            end
            
            clear user_event_times uevind
            
            
            % find onset/offset indices for each track
            onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,onset_time);
            offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offset_time);
            onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,onset_time);
            offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offset_time);
            
            % convert to dataVals struct
            if mode < 3
                dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';                     % f0 track from onset to offset
                for f=1:size(sigmat.ftrack,1)
                    fname=sprintf('f%d',f);
                    dataVals(i).(fname)  = sigmat.ftrack(f,onsetIndfx:offsetIndfx)';
                end
                dataVals(i).int          = sigmat.ampl(onsetIndAmp:offsetIndAmp)';          % intensity (rms amplitude) track from onset to offset
                dataVals(i).pitch_taxis  = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';     % pitch time axis
                dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';    % formant time axis
                dataVals(i).ampl_taxis   = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';    % amplitude time axis
                dataVals(i).dur          = offset_time - onset_time;                        % duration
                
            else
                dataVals(i).f0{v} = sigmat.pitch(onsetIndf0:offsetIndf0)';                     % f0 track from onset to offset
                for f=1:size(sigmat.ftrack,1)
                    fname=sprintf('f%d',f);
                    dataVals(i).(fname){v}  = sigmat.ftrack(f,onsetIndfx:offsetIndfx)';
                end
                dataVals(i).int{v}          = sigmat.ampl(onsetIndAmp:offsetIndAmp)';          % intensity (rms amplitude) track from onset to offset
                dataVals(i).pitch_taxis{v}  = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';     % pitch time axis
                dataVals(i).ftrack_taxis{v} = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';    % formant time axis
                dataVals(i).ampl_taxis{v}   = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';    % amplitude time axis
                dataVals(i).dur{v}          = offset_time - onset_time;                        % duration
            end
            
            if v == 1
                dataVals(i).word = expt.allWords(trialnum);                                 % numerical index to word list (e.g. 2)
                dataVals(i).vowel = expt.allVowels(trialnum);                               % numerical index to vowel list (e.g. 1)
                if isfield(expt,'allColors')
                    dataVals(i).color = expt.allColors(trialnum);                           % numerical index to color list (e.g. 1)
                end
                dataVals(i).cond = expt.allConds(trialnum);                                 % numerical index to condition list (e.g. 1)
                dataVals(i).token = trialnum;                                               % trial number (e.g. 22)
                dataVals(i).bExcl = 0;                                                      % binary variable: 1 = exclude trial, 0 = don't exclude trial
            end
            
            % warn about short tracks
            if ~dataVals(i).bExcl && mode < 3 && sum(~isnan(dataVals(i).f0)) < 20
                shortTracks = [shortTracks dataVals(i).token]; %#ok<*AGROW>
                warning('Short pitch track: trial %d',dataVals(i).token);
            end
            if ~dataVals(i).bExcl && mode < 3 && sum(~isnan(dataVals(i).f1)) < 20
                shortTracks = [shortTracks dataVals(i).token];
                warning('Short formant track: trial %d',dataVals(i).token);
            end
            %warn about >= 2 user events, if we're doing single segment tracking that's not MFA
            if numUserEvents > 2 && mode == 1 && numUserEventsInTrial1 <= 2
                tooManyEvents = [tooManyEvents dataVals(i).token];
                warning('Trial %d has %d user events when 0-2 were expected', dataVals(i).token, numUserEvents);
            end
        end
    
    end
    
end


if ~isempty(shortTracks)
    shortTracks = unique(shortTracks);
    warning('Short track list: %s',num2str(shortTracks));
end

if ~isempty(tooManyEvents)
    tooManyEvents = unique(tooManyEvents);
    warning('Trials with more than 2 user events: %s', num2str(tooManyEvents));
end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedfiles),savefile)

end %EOF


function [ind] = get_index_at_time(taxis,t)
% Simple binary search to find the corresponding t-axis value

low = 1; high = length(taxis);

while (high - low > 1)
    cand_ind = round((high+low)/2);
    if t < taxis(cand_ind)
        high = cand_ind;
    else
        low = cand_ind;
    end
end

if abs(high-t) > abs(low-t), ind = low;
else, ind = high;
end

end


function [dataVals] = makeEmptyCells(dataVals, i, numVowels, sigmat)
% Populates certain fields with the right number of empty cell arrays.

for v = 1:numVowels
    dataVals(i).f0{v} = [];
    for f=1:size(sigmat.ftrack,1)
        fname=sprintf('f%d',f);
        dataVals(i).(fname){v}  = [];
    end
    dataVals(i).int{v}          = [];
    dataVals(i).pitch_taxis{v}  = [];
    dataVals(i).ftrack_taxis{v} = [];
    dataVals(i).ampl_taxis{v}   = [];
    dataVals(i).dur{v}          = [];
end

end