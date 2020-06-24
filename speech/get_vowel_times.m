function [times] = get_vowel_times(dataPath,trialdir)

if nargin < 1 || isempty(dataPath), dataPath=cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end

times = struct;

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
times = struct([]);
for i = 1:length(sortedfiles)
    trialnum = sortedfiles(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename));
    
    % skip bad trials, except for adding metadata
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params) && ~trialparams.event_params.is_good_trial
        times(i).word = expt.allWords(trialnum);
        times(i).vowel = expt.allVowels(trialnum);
        if isfield(expt,'allColors')
            times(i).color = expt.allColors(trialnum);
        end
        times(i).cond = expt.allConds(trialnum);
        times(i).token = trialnum;
        times(i).bExcl = 1;
    else
        % find onset
        if exist('trialparams','var') & isfield(trialparams,'event_params') & ~isempty(trialparams.event_params) & ~isempty(trialparams.event_params.user_event_times) %#ok<AND2>
            % disregard if earliest is sil or sp
            %             if (strcmpi(uevnames{1},'silStart'))% || (strcmpi(uevnames{1},'spStart'))
            %                 trialparams.event_params.user_event_times(1) = [];
            %                 trialparams.event_params.user_event_names = trialparams.event_params.user_event_names{2:end};
            %             end
            if (isfield(expt,'name') && (strcmpi(expt.name,'brut') || strcmpi(expt.name,'port')|| strcmpi(expt.name,'brutGerman')|| strcmpi(expt.name,'portGerman')))
                % if (strcmpi(expt.name, 'brut') || strcmpi(expt.name,'port'))
                uevnames = trialparams.event_params.user_event_names;
                vow = expt.listVowels{trialnum};
                if strcmpi(vow,'oe')
                    vow = 'ah';
                end
                
                %                if ~exist('uevind','var') || isempty(uevind)
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
                    uevind = uevind(1)
                end
                if isempty(uevind)
                    if (strcmpi(expt.listWords{trialnum},'oeuf') || strcmpi(expt.listWords{trialnum},'neuf'))
                        onset_name='spnStart'; % Sarah needs to figure out why this is happening and fix it
                        uevind = find(contains(uevnames,onset_name));
                    end
                end
                
                %                end
                if exist('uevind','var')
                    onset_time = trialparams.event_params.user_event_times(uevind);
                end
                sprintf('trialnumber %d, word %s',trialnum, expt.listWords{trialnum});
                % end
            else
                % find time of user-created onset event
                user_event_times = sort(trialparams.event_params.user_event_times);
                onset_time = user_event_times(1);
            end
            %             if size(onset_time,2) > 1 % added for german; check with Sarah if there are problems.
            %                 onset_time = onset_time(1);
            %             end
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
        if exist('user_event_times','var') && length(user_event_times) > 1 && user_event_times(1) ~= user_event_times(end)
            % find time of user-created offset event
            offset_time = user_event_times(end);
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
        
        if exist('user_event_times','var')
            clear user_event_times
        end
        
        if exist('uevind','var')
            clear uevind
        end
        times(i).onset = onset_time;
        times(i).offset = offset_time;
    end
end