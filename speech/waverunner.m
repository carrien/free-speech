function [] = waverunner(dataPath,trialinds,buffertype,bSaveCheck,params2overwrite)
%WAVERUNNER  Calls wave_proc on each trial in an experiment.

%% setup
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialinds = []; end
if nargin < 3 || isempty(buffertype), buffertype = 'signalIn'; end
if nargin < 4 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 5, params2overwrite = []; end

% load data
load(fullfile(dataPath,'data.mat'),'data');

% pick trials
if isempty(trialinds)
    trials2track = 1:length(data);
else
    trials2track = trialinds;
end

% set trial folder
if strcmp(buffertype,'signalIn'), trialfolder = 'trials';
else trialfolder = sprintf('trials_%s',buffertype);
end
if ~exist(fullfile(dataPath,trialfolder),'dir')
    mkdir(fullfile(dataPath,trialfolder))
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
    sigproc_params.fs = data(1).params.fs;
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
        saveddata = load(savefile);
        trialparams = saveddata.trialparams;        % load saved trial params
        fieldns = fieldnames(trialparams.sigproc_params);
        for i=1:length(fieldns)                     % use previously saved params
            if ~sum(strcmp(fieldns{i},params2overwrite))
                sigproc_params.(fieldns{i}) = trialparams.sigproc_params.(fieldns{i});
            end
        end        
    else clear sigmat trialparams
    end
    
    % now overwrite default/previous sigproc_params at will
    % e.g.
    % new_sigproc_params.pitchlimits = [50 300];
    % etc.
    if exist('new_sigproc_params','var') && isstruct(new_sigproc_params)
        fields2overwrite = fieldnames(new_sigproc_params);
    else fields2overwrite = [];
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
    if bSave,
        if exist(savefile,'file')
            sigmat = saveddata.sigmat;      % load saved tracks
            fieldns = fieldnames(tracks);
            for i=1:length(fieldns)         % only overwrite newly tracked params
                sigmat.(fieldns{i}) = tracks.(fieldns{i});
            end
        else
            sigmat = tracks;
        end
        trialparams.sigproc_params = sigproc_params;    % only overwrite sigproc_params (leave event/plot_params if they exist)
        save(savefile,'sigmat','trialparams');
    end
    
end

fprintf('\n');