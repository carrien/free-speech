function [] = audioGUI(dataPath,trialnums,buffertype,figpos,bSaveCheck)
%AUDIOGUI  Wrapper for wave_viewer.
%   AUDIOGUI(DATAPATH,TRIALNUMS,BUFFERTYPE,FIGPOS,PITCHLIMITS,BSAVECHECK)
%   sends audio data found in DATAPATH to the wave_viewer analysis program.
%   This path must contain a file called data.mat with each trial n stored
%   in data(n).[fieldname]. TRIALNUMS specifies the trials to analyze (if
%   empty, all trials are used). BUFFERTYPE names the field in the data.mat
%   structure to use (e.g. 'signalIn'). FIGPOS overrides the default figure
%   position. BSAVECHECK is a binary variable specifying whether to check
%   via a user dialog before overwriting existing files (1 = yes, 0 = no).
%
%CN 2011

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialnums = []; end
if nargin < 3 || isempty(buffertype), buffertype = 'signalIn'; end
if nargin < 4, figpos = []; end
if nargin < 5, bSaveCheck = 1; end


% load data
load(fullfile(dataPath,'data.mat'),'data');

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
if strcmp(buffertype,'signalIn'), trialfolder = 'trials';
else, trialfolder = sprintf('trials_%s',buffertype);
end
if ~exist(fullfile(dataPath,trialfolder),'dir')
    mkdir(fullfile(dataPath,trialfolder))
end

% load sigproc_params and plot_params, if they exist
wvpfile = fullfile(dataPath,'wave_viewer_params.mat');
if (exist(wvpfile,'file') == 2)
    wvp = load(wvpfile);
end

% loop through trials
for itrial = trials2track
    %% prepare inputs
    y = data(itrial).(buffertype);
    
    if isfield([data.params],'fs')
        fs = data(itrial).params.fs;
    else
        fs = data(itrial).params.sr;
    end
    
    % if trial data exists, load event params and overwrite default params
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial));
    tgFilename = sprintf('AudioData_%d.TextGrid',itrial);
    tgPath =  fullfile(dataPath,'PostAlignment',tgFilename);
    if exist(savefile,'file')
        load(savefile);
        run_get_tgs = 1;
        if isfield(trialparams,'sigproc_params'), sigproc_params = trialparams.sigproc_params; else, sigproc_params = [];end
        if isfield(trialparams,'plot_params'), plot_params = trialparams.plot_params; else, plot_params = []; end
        if isfield(trialparams,'event_params'), event_params = trialparams.event_params;
            % if ~any events that do not begin with uev, then run get
            % events from tgs
            if isfield(trialparams.event_params,'user_event_names')
                if ~isempty(event_params.user_event_names)
                    for ev = 1:length(event_params.user_event_names)
                        if strncmp(event_params.user_event_names(ev),'uev',3)
                            continue
                        else
                            run_get_tgs = 0;
                            break
                        end
                    end
                end
            end
        else
            event_params = [];
        end
        if (exist(tgPath,'file') && (run_get_tgs == 1))
            [tg_user_event_times, tg_user_event_names] = get_uev_from_tg_mpraat(tgPath);
            if ~isfield(event_params,'user_event_times')
                event_params.user_event_times = [];
                event_params.user_event_names = [];
            end
            event_params.user_event_times = [event_params.user_event_times, tg_user_event_times];
            event_params.user_event_names = [event_params.user_event_names, tg_user_event_names];
        end
        
        
    else
        % if trial doesn't already exist...
        sigproc_params = [];
        event_params = [];
        plot_params = [];
        sigmat = [];
        if exist(tgPath,'file')
            % % check to see if UEV's exist, delete and replace textgrid uevs
            %         rmTG = [];
            %         for i=1:length(event_params.user_event_names)
            %             if strncmp(event_params.user_event_names(i),'uev',3)
            %                 continue;
            %             else
            %                 rmTG = [rmTG, i];
            %             end
            %         end
            %         rmTG = fliplr(rmTG);
            %         for i=1:length(rmTG)
            %             event_params.user_event_names(rmTG(i)) = [];
            %             event_params.user_event_times(rmTG(i)) = [];
            %         end
            
            [tg_user_event_times, tg_user_event_names] = get_uev_from_tg_mpraat(tgPath);
            %...if trial doesn't already exist,
            %event_params.user_event_times won't exist yet either.
            event_params.user_event_times = [tg_user_event_times];
            event_params.user_event_names = [tg_user_event_names];
        end
    end
    
    if ~exist('sigmat','var')
        sigmat = []; %needed in case trial has been marked as bad but not analyzed yet
    end
    % check for existence of TextGrids from alignment and append events if
    % necessary
    
    
    if isempty(sigproc_params)
        if exist('wvp','var') % otherwise, use param file if it exists
            sigproc_params = wvp.sigproc_params;
        elseif exist('endstate','var') % otherwise, use last trial's params
            sigproc_params = endstate.sigproc_params;
        else % otherwise, get defaults
            sigproc_params = get_sigproc_defaults;
        end
    end
    if isempty(plot_params) %separate out where to look for plot_params and sigproc_params
        if exist('wvp','var') % otherwise, use param file if it exists
            plot_params = wvp.plot_params;
        elseif exist('endstate','var') % otherwise, use last trial's params
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
    endstate = wave_viewer(y,'fs',fs,'name',sprintf('trial(%d)',itrial), ...
        'nformants',2,'sigproc_params',sigproc_params, ...
        'plot_params',plot_params,'event_params',event_params,...
        'sigmat',sigmat);
    
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
    
    if strcmp(endstate.name,'end'), break; end
end

% save param file
sigproc_params = endstate.sigproc_params;
plot_params = endstate.plot_params;
bSave = savecheck(wvpfile);
if bSave, save(wvpfile,'sigproc_params','plot_params'); end
