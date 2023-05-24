function dataVals = gen_dataVals_from_wave_viewer(dataPath,trialdir,bSaveCheck,bMultiSegment,vowel_list)
%GEN_DATAVALS  Scrape subject trial files for data and save.
%   GEN_DATAVALS(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%   BMULTISEGMENT (optional). If set to 0 (default), a single track is
%     extracted for each trial, controlled more specifically by EVENTMODE.
%     If set to 1, multiple tracks are extracted, one per "segment" (the
%     interval between each pair of consecutive user events), and saved as
%     a cell array, where each cell is the data from one segment.
%   VOWEL_LIST (optional). A cell array of strings. In a trial, the first
%     user event whose name is on vowel_list will be the segment onset.
%
%CN 3/2010

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 4 || isempty(bMultiSegment), bMultiSegment = 0; end
if nargin < 5, vowel_list = []; end

% check for existing dataVals file
savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if ~bSave, return; end

% load processing parameters
load(fullfile(dataPath,'expt.mat'), 'expt');
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'), 'sigproc_params');
else
    sigproc_params = get_sigproc_defaults;
end

% get trial numbers
trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
[sortedTrialnums,sortedFilenames] = get_sortedTrials(trialPath);

%% determine mode (whether to use event names to define tracks):
%  * eventMode 1 is the traditional use case and ignores event names.
%  * eventMode 2 uses event names that match a list to select relevant segments.
if ~bMultiSegment
    vowel_list_default = {'IY' 'IH' 'EY' 'EH' 'AE' 'AA' 'AH' 'AO' 'OW' 'UH' 'UW' 'ER' 'OY' 'AY' 'AW' 'EYStart' 'AHStart' 'UWStart' 'IYStart' 'EHStart' 'AEStart' 'UHStart' 'spnStart'};
    
    % get user event names in first good trial to determine eventMode
    firstGoodTrial = 1;
    while ~exist('uev_trial1','var')
        load(fullfile(trialPath,sortedFilenames{firstGoodTrial}), 'trialparams');
        try
            bHasUevs = ~isempty(trialparams.event_params.user_event_names);
        catch
            bHasUevs = false;
        end
        try
            bGoodTrial = trialparams.event_params.is_good_trial;
        catch
            bGoodTrial = 1;
        end
        
        if bGoodTrial && bHasUevs
            uev_trial1 = trialparams.event_params.user_event_names;
        else
            firstGoodTrial = firstGoodTrial + 1;
        end
        
        if firstGoodTrial > length(sortedFilenames)
            uev_trial1 = '';
            break; % escape if no good trials
        end 
    end
    
    % if you supply a vowel list, assume eventMode 2
    if ~isempty(vowel_list)
        eventMode = 2;
        if ~any(contains(uev_trial1, vowel_list))
            warning('You supplied a vowel list, but trial %d did not contain any user events with a name on the list. The function will continue and look for events matching the supplied list.',firstGoodTrial);
        end
    % if any user event name matches the default vowel list, assume eventMode 2
    elseif any(contains(uev_trial1, vowel_list_default))
        eventMode = 2;
        vowel_list = vowel_list_default;
        fprintf('A user event in trial %d matched a vowel name. Segments will be selected based on event names.\n',firstGoodTrial);
    % if no events match vowel names, default to eventMode 1
    else
        eventMode = 1;
    end
end

%% loop over each trial and populate dataVals
shortTracks = [];
tooManyEvents = [];

for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    try
        filename = sortedFilenames{i};
        load(fullfile(trialPath,filename), 'sigmat', 'trialparams');

        if isfield(trialparams,'event_params') && isfield(trialparams.eventparams,'user_event_times')
            numUserEvents = length(trialparams.event_params.user_event_times);
        else
            numUserEvents = 0;
        end

        % reorder events first-to-last
        if numUserEvents >= 2
            event_times = trialparams.event_params.user_event_times;
            event_names = trialparams.event_params.user_event_names;

            [~, sortOrder] = sort(event_times(:));
            if ~isequal(sortOrder', 1:numUserEvents) % events not ordered first-to-last
                fprintf('Reordering events for trial %d\n', trialnum);
                trialparams.event_params.user_event_times = event_times(sortOrder);
                trialparams.event_params.user_event_names = event_names(sortOrder);
                save(fullfile(trialPath,filename), 'sigmat', 'trialparams');
            end
        end

        if isfield(trialparams,'event_params') && isfield(trialparams.eventparams,'is_good_trial')
            bGoodTrial = trialparams.event_params.is_good_trial;
        else
            bGoodTrial = 1; % if field doesn't exist, assume it's good
        end

        if bGoodTrial
            % get timing of events, either from user events or otherwise
            if bMultiSegment
                event_times = trialparams.event_params.user_event_times;
                event_names = trialparams.event_params.user_event_names;
            else
                [event_times, event_names] = get_events(sigmat, trialparams, sigproc_params, eventMode, vowel_list, trialnum);
            end

            % populate formant and signal data based on events
            dataValsTrial = get_dataValsTrial_fromEvents(sigmat, event_times, event_names);

            % convert certain dataVals fields from cell to single instance array
            if ~bMultiSegment && iscell(dataValsTrial.f0)
                for field = {'f0' 'f1' 'f2' 'int' 'pitch_taxis' 'ftrack_taxis' 'ampl_taxis' 'dur' 'segment'}
                    dataValsTrial.(field{:}) = dataValsTrial.(field{:}){:};
                end
            end

            % tally short tracks
            if ~bMultiSegment && (sum(~isnan(dataValsTrial.f0)) < 20 || sum(~isnan(dataValsTrial.f1)) < 20)
                shortTracks = [shortTracks trialnum]; %#ok<*AGROW>
            end

            %warn about >= 2 user events if only expecting one
            if numUserEvents > 2 && ~bMultiSegment && eventMode == 1
                tooManyEvents = [tooManyEvents trialnum];
                warning('Trial %d has %d user events when 2 or fewer were expected', trialnum, numUserEvents);
            end
        else
            % if not a good trial, populate dataValsTrial fields with empty arr
            for field = {'f0' 'f1' 'f2' 'int' 'pitch_taxis' 'ftrack_taxis' 'ampl_taxis' 'dur' 'segment'}
                dataValsTrial.(field{:}) = [];
            end
        end

        % add fields used in all modes
        dataValsTrial.word = expt.allWords(trialnum);
        if isfield(expt, 'allVowels'), dataValsTrial.vowel = expt.allVowels(trialnum); end
        if isfield(expt, 'allColors'), dataValsTrial.color = expt.allColors(trialnum); end
        if isfield(expt,'allConds'),   dataValsTrial.color = expt.allConds(trialnum);  end
        dataValsTrial.token = trialnum;
        dataValsTrial.bExcl = double(~bGoodTrial); %consider changing bExcl to a logical (rather than numeric) at some point

        %now that dataValsTrial has all fields, can set as a row in dataVals
        dataVals(i) = dataValsTrial;
        clear dataValsTrial;
    catch e
        fprintf('\nError occurred during execution of trial %d\n\n', trialnum);
        rethrow(e)
    end
    
end

%% show warnings
if ~isempty(shortTracks)
    shortTracks = unique(shortTracks);
    warning('Short track list: %s',num2str(shortTracks));
end

if ~isempty(tooManyEvents)
    tooManyEvents = unique(tooManyEvents);
    warning('Trials with more than 2 user events: %s', num2str(tooManyEvents));
end

%% save it
save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile)

end %EOF


function [event_times, event_names] = get_events(sigmat, trialparams, sigproc_params, eventMode, vowel_list, trialnum)
% depending on mode, use some method of determining segment onset/offset
%
% eventMode 1 (default) is the traditional use case. From each trial,
%   we extract one track whose start and end times are determined by:
%   * [If 2+ user events] the first and last user events
%   * [If 1 user event] the user event and the next subthreshold amplitude
%   * [If 0 user events] the first suprathreshold amplitude and the next subthreshold amplitude (i.e., the first contiguous formant track)
%
% eventMode 2 extracts one track determined by matching event names to a list.
%   The start time is the first user event whose name is in vowel_list.
%   The end time is the next user event (if there isn't one, the above
%   rules for eventMode 1 are used for determining the offset).

try
    uev_times = trialparams.event_params.user_event_times;
    uev_names = trialparams.event_params.user_event_names;
    numUserEvents = length(trialparams.event_params.user_event_times);
catch % if fields don't exist
    uev_times = [];
    uev_names = [];
    numUserEvents = 0;
end

switch eventMode
    case 1
        %% mode 1:
        % find onset: the first user event
        if numUserEvents >= 1
            [~, onset_ix] = min(uev_times);
            onset_time = uev_times(onset_ix);
            onset_name = uev_names(onset_ix);
        else % if no user events, use ampl threshold
            [onset_time,onset_name] = get_onset_from_ampl(sigmat,trialparams,sigproc_params);
        end
        
        % find offset: the last user event
        if numUserEvents >= 2
            [~, offset_ix] = max(uev_times);
            offset_time = uev_times(offset_ix);
            offset_name = uev_names(offset_ix);
        else % if fewer than 2 user events, use ampl threshold
            [~, onsetIndAmp] = min(abs(sigmat.ampl_taxis - onset_time));
            [offset_time,offset_name] = get_offset_from_ampl(sigmat,trialparams,sigproc_params,onsetIndAmp);
        end
        
    case 2
        %% mode 2:
        if isempty(uev_times)
            error('No events found in trial %d.', trialnum)
        end
        
        % find onset: the first user event whose name is in vowel_list
        onset_ix = find(ismember(uev_names, vowel_list), 1);
        if isempty(onset_ix)
            error('No matching events found in trial %d.', trialnum)
        end
        onset_time = uev_times(onset_ix);
        onset_name = uev_names(onset_ix);
        
        % find offset: the next user event
        if onset_ix < numUserEvents
            offset_time = uev_times(onset_ix + 1);
            offset_name = uev_names(onset_ix + 1);
        else % or the next subthreshold time, if there is no next event
            [~, onsetIndAmp] = min(abs(sigmat.ampl_taxis - onset_time));
            [offset_time,offset_name] = get_offset_from_ampl(sigmat,trialparams,sigproc_params,onsetIndAmp);
        end
        
end

%% return
event_times(1) = onset_time;
event_names{1} = onset_name;
event_times(2) = offset_time;
event_names{2} = offset_name;

end %EOF

%%
function [onset_time,onset_type] = get_onset_from_ampl(sigmat,trialparams,sigproc_params)

% choose threshold
if ~isempty(trialparams.sigproc_params) % use trial-specific amplitude threshold
    ampl_thresh4voicing = trialparams.sigproc_params.ampl_thresh4voicing;
    onset_type = 'trial amplitude onset';
else                                    % use wave_viewer_params default amplitude threshold
    ampl_thresh4voicing = sigproc_params.ampl_thresh4voicing;
    onset_type = 'default amplitude onset';
end

% find onset
onsetIndAmp = find(sigmat.ampl > ampl_thresh4voicing);
if onsetIndAmp
    onsetIndAmp = onsetIndAmp(1) + 1;
else
    onsetIndAmp = 1;
    onset_type = 'no amplitude onset found';
end
onset_time = sigmat.ampl_taxis(onsetIndAmp);

end %EOF

%%
function [offset_time,offset_type] = get_offset_from_ampl(sigmat,trialparams,sigproc_params,onsetIndAmp)

% choose threshold
if ~isempty(trialparams.sigproc_params) % use trial-specific amplitude threshold
    ampl_thresh4voicing = trialparams.sigproc_params.ampl_thresh4voicing;
    offset_type = 'trial amplitude offset';
else                                    % use wave_viewer_params default amplitude threshold
    ampl_thresh4voicing = sigproc_params.ampl_thresh4voicing;
    offset_type = 'default amplitude onset';
end

% find offset
offsetIndAmp = find(sigmat.ampl(onsetIndAmp:end) < ampl_thresh4voicing);
if offsetIndAmp
    offsetIndAmp = offsetIndAmp(1) + onsetIndAmp-2; % correct indexing
else % use last index if no offset found
    offsetIndAmp = length(sigmat.ampl);
    offset_type = 'end of trial';
end
offset_time = sigmat.ampl_taxis(offsetIndAmp);

end %EOF
