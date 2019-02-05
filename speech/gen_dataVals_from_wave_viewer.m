function [] = gen_dataVals_from_wave_viewer(dataPath,trialdir,bSaveCheck)
%GEN_DATAVALS  Scrape subject trial files for data and save.
%   GEN_DATAVALS(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%CN 3/2010

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end


savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if ~bSave, return; end

load(fullfile(dataPath,'expt.mat'));
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
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

% Append '.mat' and load
dataVals = struct([]);
for i = 1:length(sortedfiles)
    trialnum = sortedfiles(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename));
    
    % skip bad trials, except for adding metadata
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params) && ~trialparams.event_params.is_good_trial
        dataVals(i).word = expt.allWords(trialnum);
        dataVals(i).vowel = expt.allVowels(trialnum);
        if isfield(expt,'allColors')
            dataVals(i).color = expt.allColors(trialnum);
        end
        dataVals(i).cond = expt.allConds(trialnum);
        dataVals(i).token = trialnum;
        dataVals(i).bExcl = 1;
    else
        % find onset
        if exist('trialparams','var') & isfield(trialparams,'event_params') & ~isempty(trialparams.event_params) & trialparams.event_params.user_event_times %#ok<AND2>
            % find time of user-created onset event
            user_event_times = sort(trialparams.event_params.user_event_times);
            onset_time = user_event_times(1);
            timediff = sigmat.ampl_taxis - onset_time;
            [~, onsetIndAmp] = min(abs(timediff));
        else
            % use amplitude threshold to find onset index
            if exist('trialparams','var') && ~isempty(trialparams.sigproc_params) 
                % use trial-specific amplitude threshold
                onsetIndAmp = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
            else % use wave_viewer_params default amplitude threshold
                onsetIndAmp = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
            end
            if onsetIndAmp, onsetIndAmp = onsetIndAmp(1) + 1;
            else onsetIndAmp = 1; % set trial BAD here? reason: no onset found?
            end
            onset_time = sigmat.ampl_taxis(onsetIndAmp);
        end

        % find offset
        if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params) && length(trialparams.event_params.user_event_times) > 1 ...
                && trialparams.event_params.user_event_times(1) ~= trialparams.event_params.user_event_times(2)
            % find time of user-created offset event
            offset_time = user_event_times(2); % make sure that user_event_times gets set above (line 44)
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

        % find onset/offset indices for each track
        onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,onset_time);
        offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offset_time);
        onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,onset_time);
        offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offset_time);

        % convert to dataVals struct
        dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';                     % f0 track from onset to offset
        dataVals(i).f1 = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';                  % f1 track from onset to offset
        dataVals(i).f2 = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';                  % f2 track from onset to offset
        dataVals(i).int = sigmat.ampl(onsetIndAmp:offsetIndAmp)';                   % intensity (rms amplitude) track from onset to offset
        dataVals(i).pitch_taxis = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';      % pitch time axis
        dataVals(i).ftrack_taxis = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)';    % formant time axis
        dataVals(i).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';      % amplitude time axis
        dataVals(i).dur = offset_time - onset_time;                                 % duration
        dataVals(i).word = expt.allWords(trialnum);                                 % numerical index to word list (e.g. 2)
        dataVals(i).vowel = expt.allVowels(trialnum);                               % numerical index to vowel list (e.g. 1)
        if isfield(expt,'allColors')
            dataVals(i).color = expt.allColors(trialnum);                           % numerical index to color list (e.g. 1)
        end
        dataVals(i).cond = expt.allConds(trialnum);                                 % numerical index to condition list (e.g. 1)
        dataVals(i).token = trialnum;                                               % trial number (e.g. 22)
        dataVals(i).bExcl = 0;                                                      % binary variable: 1 = exclude trial, 0 = don't exclude trial

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
end

if ~isempty(shortTracks)
    shortTracks = unique(shortTracks);
    warning('Short track list: %s',num2str(shortTracks));
end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedfiles),savefile)

end

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
else ind = high;
end

end