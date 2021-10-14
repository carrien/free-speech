function [] = waverunner(dataPath,trialinds,buffertype,bSaveCheck,params2overwrite,folderSuffix)
%WAVERUNNER  Calls wave_proc on each trial in an experiment.
%   WAVERUNNER(DATAPATH,TRIALINDS,BUFFERTYPE,BSAVECHECK,PARAMS2OVERWRITE)
%   loads experiment data from DATAPATH and calls wave_proc on trials given
%   in TRIALINDS (default: all trials). BUFFERTYPE determines which field
%   to use from the data struct (default: signalIn).

%% setup
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialinds = []; end
if nargin < 3 || isempty(buffertype), buffertype = 'signalIn'; end
if nargin < 4 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 5, params2overwrite = []; end
if nargin < 6, folderSuffix = []; end

% load data
fprintf('Loading data...')
load(fullfile(dataPath,'data.mat'),'data');
fprintf(' done.\n')

% pick trials
if isempty(trialinds)
    trials2track = 1:length(data);
else
    trials2track = trialinds;
end

% set trial folder
if isempty(folderSuffix)
    if strcmp(buffertype,'signalIn')
        trialfolder = 'trials';
    else
        trialfolder = sprintf('trials_%s',buffertype);
        trialfolderSigIn = 'trials';
    end
else
    if strcmp(buffertype,'signalIn')
        trialfolder = sprintf('trials_%s',folderSuffix);
    else
        trialfolder = sprintf('trials_%s_%s',folderSuffix,buffertype);
        trialfolderSigIn = sprintf('trials_%s',folderSuffix);
    end
end
if ~exist(fullfile(dataPath,trialfolder),'dir')
    fprintf('Creating trial directory: %s\n',fullfile(dataPath,trialfolder));
    mkdir(fullfile(dataPath,trialfolder));
end

% set sigproc params
sigproc_params = get_sigproc_defaults;
wvpfile = fullfile(dataPath,'wave_viewer_params.mat');
if (exist(wvpfile,'file') == 2)
    wvp = load(wvpfile,'sigproc_params');
    fieldns = fieldnames(wvp.sigproc_params);
    for i=1:length(fieldns)
        sigproc_params.(fieldns{i}) = wvp.sigproc_params.(fieldns{i});
    end
else
    if isfield([data.params],'fs')
        sigproc_params.fs = data(1).params.fs;
    else
        sigproc_params.fs = data(1).params.sr;
    end
end

%% loop through trials
fprintf('Processing trial: ');
counter = 0;
for itrial = trials2track
    %% prepare inputs
    y = data(itrial).(buffertype);
    
    % if trial data exists, load it
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial));
    if (exist(savefile,'file') == 2)
        bCopyParams = 0;
        saveddata = load(savefile);
        trialparams = saveddata.trialparams;        % load saved trial params
        if isfield(trialparams,'sigproc_params')      % if sigproc_params exists, use existing values
            fieldns = fieldnames(trialparams.sigproc_params);
            for i=1:length(fieldns)                     % use previously saved params
                if ~sum(strcmp(fieldns{i},params2overwrite))
                    sigproc_params.(fieldns{i}) = trialparams.sigproc_params.(fieldns{i});
                end
            end
        end
    elseif ~strcmp(buffertype,'signalIn')
        if exist(fullfile(dataPath,trialfolderSigIn,sprintf('%d.mat',itrial)),'file') && ~exist(fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial)),'file')
            bCopyParams = 1;
            copyfile = fullfile(dataPath,trialfolderSigIn,sprintf('%d.mat',itrial));
            saveddata = load(copyfile);
            trialparams = saveddata.trialparams;        % load saved trial params
            if isfield(trialparams,'sigproc_params')      % if sigproc_params exists, use existing values
                fieldns = fieldnames(trialparams.sigproc_params);
                for i=1:length(fieldns)                     % use previously saved params
                    if ~sum(strcmp(fieldns{i},params2overwrite))
                        sigproc_params.(fieldns{i}) = trialparams.sigproc_params.(fieldns{i});
                    end
                end
            end
            
            %calculate lag between input and output signals
            cutoffSamp1 = find(isnan(data(itrial).signalOut), 1 );
            if ~isempty(cutoffSamp1)
                endSamp = cutoffSamp1-1;
            else
                endSamp = length(data(itrial).signalOut);
            end
            [r,lags] = xcorr(data(itrial).signalOut(1:endSamp),data(itrial).signalIn(1:endSamp));
            [rmax,imax] = max(r);
            offsetMs = lags(imax)/data(itrial).params.sr;
            
            if isfield(trialparams,'event_params')      % if event_params exists, copy them
                fieldns = fieldnames(trialparams.event_params);
                for i=1:length(fieldns)                     % use previously saved params
                    if ~sum(strcmp(fieldns{i},params2overwrite))
                        event_params.(fieldns{i}) = trialparams.event_params.(fieldns{i});
                        if strcmp(fieldns{i},'user_event_times')
                            event_params.(fieldns{i}) = event_params.(fieldns{i})+offsetMs; %account for delay between in and out signals
                        end
                    end
                end
            end
        else
            bCopyParams = 0;
        end
    else clear sigmat trialparams
    end
    
    % now overwrite default/previous sigproc_params at will
    % e.g.
    % new_sigproc_params.pitchlimits = [50 300];
    %new_sigproc_params.preemph = 1.95;
    %new_sigproc_params.nlpc = 11;
    % etc.
    
    if exist('new_sigproc_params','var') && isstruct(new_sigproc_params)
        fields2overwrite = fieldnames(new_sigproc_params);
    else
        fields2overwrite = [];
    end
    for i=1:length(fields2overwrite)
        sigproc_params.(fields2overwrite{i}) = new_sigproc_params.(fields2overwrite{i});
        if itrial == trials2track(1)
            warning('Overwrote value of %s to %s. ',fields2overwrite{i},num2str(sigproc_params.(fields2overwrite{i})));
        end
    end
    
    % display trialnum
    if ~mod(counter,25), fprintf('\n'); end
    counter = counter + 1;
    fprintf('%d ',itrial);
    
    
    %% process the audio
    tracks = wave_proc(y,sigproc_params);
    
    %% save outputs
    if bSaveCheck
        bSave = savecheck(savefile);
    else
        bSave = 1;
    end
    if bSave
        if exist(savefile,'file') && isfield(saveddata,'sigmat')
            sigmat = saveddata.sigmat;      % load saved tracks
            fieldns = fieldnames(tracks);
            for i=1:length(fieldns)         % only overwrite newly tracked params
                sigmat.(fieldns{i}) = tracks.(fieldns{i});
            end
        else
            sigmat = tracks;
        end
        trialparams.sigproc_params = sigproc_params;    % only overwrite sigproc_params (leave event/plot_params if they exist)
        
        if exist('bCopyParams','var') && bCopyParams == 1 %overwrite event_params if copying from signalIn to signalOut
            trialparams.event_params = event_params;
        end
        
        % if TextGrid exists (and isn't in event list), add TextGrid events
        tgFilename = sprintf('AudioData_%d.TextGrid',itrial);
        tgPath = fullfile(dataPath,'PostAlignment',tgFilename);
        if exist(tgPath,'file')
            if ~isfield(trialparams,'event_params') || ~isfield(trialparams.event_params,'user_event_names')
                trialparams.event_params.user_event_names = [];
                trialparams.event_params.user_event_times = [];
            end
            if isempty(trialparams.event_params.user_event_names) ... % if there are no events
                    || all(strncmp(trialparams.event_params.user_event_names,'uev',3)) % or if all event names start with uev
                % no TextGrid events exist: add them
                fprintf('Adding events from TextGrid.\n')
                [tg_user_event_times, tg_user_event_names] = get_uev_from_tg_mpraat(tgPath);
                trialparams.event_params.user_event_times = [trialparams.event_params.user_event_times, tg_user_event_times];
                trialparams.event_params.user_event_names = [trialparams.event_params.user_event_names, tg_user_event_names];
            end
        end
        
        save(savefile,'sigmat','trialparams');
    end
    
end

fprintf('\n');