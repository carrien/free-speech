function [] = gen_dataVals_from_wave_viewer(dataPath,trialdir,bSaveCheck, bMultiSegment, vowel_list)
%GEN_DATAVALS  Scrape subject trial files for data and save.
%   GEN_DATAVALS(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%   BMULTISEGMENT (optional). If set to 1, function will output a cell
%     array of segments between user events. If 0, function will find a
%     single segment in each trial, controlled more specifically by MODE.
%   VOWEL_LIST (optional). A cell array of strings. In a trial, the first
%     user event whose name is on vowel_list will be the segment onset.
%
%CN 3/2010

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 4 || isempty(bMultiSegment)
    bMultiSegment = 0;
end
if nargin < 5, vowel_list = []; end


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

%use presence of user event name in trial 1 to determine mode 1 or 2
filename = sprintf('%d.mat',sortedfiles(1));
load(fullfile(trialPath,filename), 'trialparams');

try
    uev_trial1 = trialparams.event_params.user_event_names;
catch
    uev_trial1 = {''};
end

%% determine mode
% EXPLAINING MODES:
% MODE 1 is the default and traditional use case. Each trial has one
%   segment which is tracked. This segment is one of:
%   * [If no user events] The period of the first contiguous formant track
%   * [If 2+ user events] The period between the first and last user events
%   * [If 1 user event] The period between the only user event and:
%         ** the end of the current contiguous formant track, OR
%         ** when the amplitude goes below the default amplitude threshold
% MODE 2 also tracks one segment. It tracks the first vowel, when the trial
%   was passed through the Montreal Forced Aligner (MFA). This is used in
%   the vsaSentence transfer words, and brut and port experiments.
%  The tracked segment's onset is:
%   * the first user event whose name is the same as one of the mfa_vowels
%  The tracked segment's offset is:
%   * the next user event, or
%   * if there is not a user event after the mfa_vowel "onset", then the
%       MODE 1 rules are used for determining the offset.
% MODE 3 tracks multiple segments. It tracks the period between any two
%   consecutive user events. It saves dataVals as a cell array, where each
%   cell is the data from one segment.
%
%   For example, a trial with 4 user events will have a 3-cell array in
%   dataVals, representing the periods between user events 1-2, 2-3, & 3-4.

if bMultiSegment
    mode = 3;
else % if single segment, distinguish between mode 1 and 2 
    vowels_brutPort = {'EYStart' 'AHStart' 'UWStart' 'IYStart' 'EHStart' 'AEStart' 'UHStart'};
    vowels_default = {'IY' 'IH' 'EY' 'EH' 'AE' 'AA' 'AH' 'AO' 'OW' 'UH' 'UW' 'ER' 'OY' 'AY' 'AW'};
    
    % if you supply a vowel list, assume mode 2
    if ~isempty(vowel_list) 
        mode = 2;
        if ~any(contains(uev_trial1, vowel_list))
            warning(['You supplied a vowel list, but trial 1 did not contain any ' ...
                'user events with a name on the vowel list. The function will continue and ' ...
                'will look for segments that begin with vowels in the supplied vowel list.']);
        end
        
    % if a user event name matches the output of Montreal Forced Aligner, assume mode 2
    elseif any(contains(uev_trial1, vowels_brutPort)) && isfield(expt,'name') && ...
            contains(expt.name, {'brut', 'port' 'brutGerman' 'portGerman'}, 'IgnoreCase', true)
        mode = 2;
        vowel_list = vowels_brutPort;
        fprintf(['Segments will be selected based on events with vowel names '...
            'pre-specified for brut and port experiments.\n']);
    elseif any(contains(uev_trial1, vowels_default))
        mode = 2;
        vowel_list = vowels_default;
        fprintf(['A user event with a vowel name was found in trial 1. '...
            'Segments will be selected based on events with vowel names.\n']);
    else
        mode = 1;
    end
end

%% loop over each trial and populate dataVals
for i = 1:length(sortedfiles)
    trialnum = sortedfiles(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename), 'sigmat', 'trialparams');
    
    numUserEvents = length(trialparams.event_params.user_event_times);
    
    try
        bGoodTrial = trialparams.event_params.is_good_trial;
    catch
        bGoodTrial = 1; % if field doesn't exist, assume it's good
    end
    
    if bGoodTrial
        % get timing of events, either from user events or otherwise
        [event_times, event_names] = get_events(expt, trialparams, sigmat, numUserEvents, trialnum, sigproc_params, vowel_list);
        
        % populate formant and signal data based on events
        dataVals(i) = get_dataValsTrial_fromEvents(sigmat, event_times, event_names);
        
        % convert certain dataVals fields from cell to single instance array
        if mode < 3 && iscell(dataVals(i).f0)
            % TODO F/U how 'dur' will be handled.
            for field = {'f0' 'f1' 'f2' 'int' 'pitch_taxis' 'ftrack_taxis' 'ampl_taxis' 'dur'}
                dataVals(i).(field{:}) = dataVals(i).(field{:}){:};
            end
        end
        
        % warn about short tracks
        if mode < 3 && sum(~isnan(dataVals(i).f0)) < 20 
            shortTracks = [shortTracks trialnum]; %#ok<*AGROW>
            warning('Short pitch track: trial %d', trialnum);
        end
        if mode < 3 && sum(~isnan(dataVals(i).f1)) < 20 
            shortTracks = [shortTracks trialnum];
            warning('Short formant track: trial %d', trialnum);
        end
        
        %warn about >= 2 user events if only expecting one
        if numUserEvents > 2 && mode == 1
            tooManyEvents = [tooManyEvents dataVals(i).token];
            warning('Trial %d has %d user events when 2 or fewer were expected', dataVals(i).token, numUserEvents);
        end
        
    else
        %TODO after looking at carrie's code, make sure this works OK and
        %everything gets set
        dataVals(i) = get_dataValsTrial_fromEvents(sigmat, [], []);
        
    end
    
    % add fields used in all modes
    dataVals(i).word = expt.allWords(trialnum);
    dataVals(i).vowel = expt.allVowels(trialnum);
    if isfield(expt,'allColors')
        dataVals(i).color = expt.allColors(trialnum);
    end
    dataVals(i).cond = expt.allConds(trialnum);
    dataVals(i).token = trialnum;
    if bGoodTrial
        dataVals(i).bExcl = 0;
    else
        dataVals(i).bExcl = 1;
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
fprintf('%d trials saved in %s.\n',length(sortedfiles),savefile)

end %EOF


function [event_times, event_names] = get_events(expt, trialparams, sigmat, numUserEvents, trialnum, sigproc_params, vowel_list)
% depending on mode, use some method of determining segment onset/offset

try
    uev_times = trialparams.event_params.user_event_times;
    uev_names = trialparams.event_params.user_event_names;
catch % if fields don't exist
    uev_times = [];
    uev_names = [];
end

% when mode == 3, no additional handling is necessary.
% All user event times are passed into get_dataValsTrial_fromEvents
if mode == 3, return; end


%% mode 2 find onset (and offset if possible)
if mode == 2 && ~isempty(uev_times)
    %find onset
    %the first user event name that's a "vowel" listed in mfa_vowels
    onset_ix = find(ismember(uev_names, vowel_list), 1);
    
    % copying this verbatim from old code - CWN
    if isempty(onset_ix)
        if (strcmpi(expt.listWords{trialnum},'oeuf') || strcmpi(expt.listWords{trialnum},'neuf'))
            onset_name='spnStart'; % Sarah needs to figure out why this is happening and fix it
            onset_ix = find(ismember(uev_names,onset_name), 1);
        end
    end
    
    event_times(1) = uev_times(onset_ix);
    event_names(1) = uev_names(onset_ix);
    
    %find offset. It's the next user event, if one exists
    if onset_ix < numUserEvents
        event_times(2) = uev_times(onset_ix + 1);
        event_names(2) = uev_names(onset_ix + 1);
    else
        [~, onsetIndAmp] = min(abs(sigmat.ampl_taxis - event_times(1))); % use later to get offset
    end
end

%% mode 1 find onset (and offset if possible)
if mode == 1 && numUserEvents >= 2
    % onset and offset are the first and last user events
    event_times(1) = uev_times(1);
    event_names(1) = uev_names(1);
    event_times(2) = uev_times(end);
    event_names(2) = uev_names(end);
elseif mode == 1 && numUserEvents == 1
    % onset is the first user event
    event_times(1) = uev_times(1);
    event_names(1) = uev_names(1);
    
    [~, onsetIndAmp] = min(abs(sigmat.ampl_taxis - event_times(1))); % use later to get offset
elseif mode == 1 && numUserEvents == 0  %if no user events, use ampl threshold to find onset
    if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
        % use trial-specific amplitude threshold
        onsetIndAmp = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
        event_names(1) = {'trial amplitude onset'};
    else % use wave_viewer_params default amplitude threshold
        onsetIndAmp = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
        event_names(1) = {'general amplitude onset'};
    end
    if onsetIndAmp
        onsetIndAmp = onsetIndAmp(1) + 1;
    else
        onsetIndAmp = 1;
        event_names(1) = {'no amplitude onset found'};
    end
    event_times(1) = sigmat.ampl_taxis(onsetIndAmp);
end

%% find offset, if you haven't found it already
if length(event_times) == 1
    if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
        % use trial-specific amplitude threshold if it exists
        offsetIndAmp = find(sigmat.ampl(onsetIndAmp:end) < trialparams.sigproc_params.ampl_thresh4voicing);
        event_times(2) = {'trial amplitude offset'};
    else % use wave_viewer_params default amplitude threshold
        offsetIndAmp = find(sigmat.ampl(onsetIndAmp:end) < sigproc_params.ampl_thresh4voicing);
        event_times(2) = {'default amplitude offset'};
    end
    if offsetIndAmp
        offsetIndAmp = offsetIndAmp(1) + onsetIndAmp-1; % correct indexing
    else % use last index if no offset found
        offsetIndAmp = length(sigmat.ampl); 
        event_names(2) = {'end of trial'};
    end
    event_times(2) = sigmat.ampl_taxis(offsetIndAmp); 
end


end %EOF
