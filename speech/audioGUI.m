function [] = audioGUI(dataPath,trialnums,buffertype,figpos,bSaveCheck,folderSuffix,varargin)
%AUDIOGUI  Wrapper for wave_viewer.
%   AUDIOGUI(DATAPATH,TRIALNUMS,BUFFERTYPE,FIGPOS,BSAVECHECK,FOLDERSUFFIX)
%   sends audio data found in DATAPATH to the wave_viewer analysis program.
%   This path must contain a file called data.mat with each trial n stored
%   in data(n).[fieldname]. TRIALNUMS specifies the trials to analyze (if
%   empty, all trials are used). BUFFERTYPE names the field in the data.mat
%   structure to use (e.g. 'signalIn'). FIGPOS overrides the default figure
%   position. BSAVECHECK is a binary variable specifying whether to check
%   via a user dialog before overwriting existing files (1 = yes, 0 = no).
%   VARARGIN takes any number of pairs of field names and field values. 
%   These are passed wholesale to wave_viewer.
%
%CN 2011

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialnums = []; end
if nargin < 3 || isempty(buffertype), buffertype = 'signalIn'; end
if nargin < 4, figpos = []; end
if nargin < 5 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 6, folderSuffix = []; end

% load data
fprintf('Loading data...')
load(fullfile(dataPath,'data.mat'),'data');
fprintf(' done.\n')

% pick trials
if isempty(trialnums)
    reply = input('Start trial? [1]: ','s');
    if isempty(reply), reply = '1'; end
    startTrial = sscanf(reply,'%d');
    trials2track = startTrial:length(data);
else
    trials2track = trialnums;
end

% set trial folder
if isempty(folderSuffix)
    if strcmp(buffertype,'signalIn')
        trialfolder = 'trials';
    else
        trialfolder = sprintf('trials_%s',buffertype);
    end
else
    if strcmp(buffertype,'signalIn')
        trialfolder = sprintf('trials_%s', folderSuffix);
    else
        trialfolder = sprintf('trials_%s_%s',folderSuffix,buffertype);
    end
end

if ~exist(fullfile(dataPath,trialfolder),'dir')
    fprintf('Creating trial directory: %s\n',fullfile(dataPath,trialfolder));
    mkdir(fullfile(dataPath,trialfolder))
end

% load sigproc_params and plot_params, if they exist
wvpfile = fullfile(dataPath,'wave_viewer_params.mat');
if (exist(wvpfile,'file') == 2)
    wvp = load(wvpfile);
end

% loop through trials
endstate.name = '';
itrial = 1;
while ~strcmp(endstate.name, 'end')
    trialNum = trials2track(itrial); % trialNum used during this loop

    %% prepare inputs
    y = data(trialNum).(buffertype);
    
    %Skip trials where signalIn is empty
    if isempty(y)
        fprintf('Trial %d has an empty signalIn field. Skipping for now.\n', trialNum)
        continue;
    end
    
    if isfield([data.params],'fs')
        fs = data(trialNum).params.fs;
    else
        fs = data(trialNum).params.sr;
    end
    
    % if trial data exists, load event params and overwrite default params
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',trialNum));
    if exist(savefile,'file')
        load(savefile); %#ok<LOAD> 
        if ~exist('sigmat','var'), sigmat = []; end % needed in case trial has been marked as bad but not analyzed yet
        if isfield(trialparams,'sigproc_params'), sigproc_params = trialparams.sigproc_params; else, sigproc_params = [];end
        if isfield(trialparams,'plot_params'), plot_params = trialparams.plot_params; else, plot_params = []; end
        if isfield(trialparams,'event_params'), event_params = trialparams.event_params; else, event_params = []; end
    else % if trial doesn't already exist...
        sigmat = [];
        sigproc_params = [];
        plot_params = [];
        event_params = [];
    end
    
    % if TextGrid exists (and isn't in event list), add TextGrid events
    tgFilename = sprintf('AudioData_%d.TextGrid',trialNum);
    tgPath = fullfile(dataPath,'PostAlignment',tgFilename);
    if exist(tgPath,'file')
        if ~isfield(event_params,'user_event_names')
            event_params.user_event_names = [];
            event_params.user_event_times = [];
        end
        if isempty(event_params.user_event_names) ... % if there are no events
                || all(strncmp(event_params.user_event_names,'uev',3)) % or if all event names start with uev
            % no TextGrid events exist: add them
            [tg_user_event_times, tg_user_event_names] = get_uev_from_tg_mpraat(tgPath);
            event_params.user_event_times = [event_params.user_event_times, tg_user_event_times];
            event_params.user_event_names = [event_params.user_event_names, tg_user_event_names];
        end
    end
    
    if isempty(sigproc_params)
        if exist('wvp','var') % otherwise, use param file if it exists
            sigproc_params = wvp.sigproc_params;
        elseif exist('endstate','var') && isfield(endstate, 'sigproc_params') % otherwise, use last trial's params
            sigproc_params = endstate.sigproc_params;
        else % otherwise, get defaults
            sigproc_params = get_sigproc_defaults;
        end
    end
    if isempty(plot_params) %separate out where to look for plot_params and sigproc_params
        if exist('wvp','var') % otherwise, use param file if it exists
            plot_params = wvp.plot_params;
        elseif exist('endstate','var') && isfield(endstate, 'plot_params') % otherwise, use last trial's params
            plot_params = endstate.plot_params;
        else % otherwise, get defaults
            plot_params = get_plot_defaults;
        end
    end

    % optionally overwrite figure position
    if ~isempty(figpos), plot_params.figpos = figpos; end

    if exist('bPraat','var')
        if bPraat
            sigproc_params.ftrack_method = 'praat';
        end
    elseif ~isempty(sigproc_params.ftrack_method) && ~strcmp(sigproc_params.ftrack_method,'praat')
        reply = input(sprintf('Formant tracking method is %s. Use praat? [y/n]: ',sigproc_params.ftrack_method),'s');
        if strcmp(reply,'y')
            sigproc_params.ftrack_method = 'praat';
            bPraat = 1;
        else
            bPraat = 0;
        end
    end
    
    %% call wave viewer
    endstate = wave_viewer(y,'fs',fs,'name',sprintf('trial(%d)',trialNum), ...
        'nformants',2,'sigproc_params',sigproc_params, ...
        'plot_params',plot_params,'event_params',event_params,...
        'sigmat',sigmat, varargin{:})
    
    %% save outputs
    trialparams.sigproc_params = endstate.sigproc_params;
    trialparams.plot_params = endstate.plot_params;
    trialparams.event_params = endstate.event_params;
    
    sigmat.ftrack = endstate.gram_axinfo.dat{2};
    sigmat.ftrack_taxis = endstate.gram_axinfo.params{2}.taxis;
    sigmat.pitch = endstate.pitch_axinfo.dat{1};
    sigmat.pitch_taxis = endstate.pitch_axinfo.params{1}.taxis;
    sigmat.ampl = endstate.ampl_axinfo.dat{1};
    sigmat.ampl_taxis = endstate.ampl_axinfo.params{1}.taxis;
    
    if bSaveCheck, bSave = savecheck(savefile); else, bSave = 1; end
    if bSave, save(savefile,'sigmat','trialparams'); end
    
    if strcmp(endstate.name,'cont') && trialNum == trials2track(end) % finish if continued on final trial
        endstate.name = 'end';
    end
    
    if strcmp(endstate.name, 'previous')
        if itrial > 1
            itrial = itrial - 1;
        else
            % if on 1st trial and press 'previous', just stay on 1st trial
        end
    else
        itrial = itrial + 1;
    end
end

fprintf('Ended on trial %d\n',trials2track(itrial-1))

% save param file
sigproc_params = endstate.sigproc_params;
plot_params = endstate.plot_params;
bSave = savecheck(wvpfile);
if bSave, save(wvpfile,'sigproc_params','plot_params'); end
