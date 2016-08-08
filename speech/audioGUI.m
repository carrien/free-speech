function [] = audioGUI(dataPath,trialinds,buffertype,figpos,pitchlimits,bSaveCheck,bFilt)
%AUDIOGUI  Wrapper for wave_viewer.
%   AUDIOGUI(DATAPATH,TRIALINDS,BUFFERTYPE,FIGPOS,PITCHLIMITS,BSAVECHECK)
%   sends audio data found in DATAPATH to the wave_viewer analysis program.
%   This path must contain a file called data.mat with each trial n stored
%   in data(n).[fieldname]. TRIALINDS specifies the trials to analyze (if
%   empty, all trials are used). BUFFERTYPE names the field in the data.mat
%   structure to use (e.g. 'signalIn'). FIGPOS overrides the default figure
%   position; PITCHLIMITS overrides the default pitch limits.
%
%CN 2011

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialinds = []; end
if nargin < 3 || isempty(buffertype), buffertype = 'signalIn'; end
if nargin < 4, figpos = []; end
if nargin < 5, pitchlimits = [50 300]; end
if nargin < 6, bSaveCheck = 1; end
if nargin < 7, bFilt = 0; end

% load data
load(fullfile(dataPath,'data.mat'),'data');

% pick trials
if isempty(trialinds)
    reply = input('Start trial? [1]: ','s');
    if isempty(reply), reply = '1'; end
    startTrial = sscanf(reply,'%d');
    trials2track = startTrial:length(data);
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

% load sigproc_params and plot_params, if they exist
wvpfile = fullfile(dataPath,'wave_viewer_params.mat');
if (exist(wvpfile,'file') == 2)    
    wvp = load(wvpfile);
end

% loop through trials
for itrial = trials2track
    %% prepare inputs
    y = data(itrial).(buffertype);

    if bFilt
        a = [.25 1 .5 0];
        f = [0 1950/(11025/2) 2200/(11025/2) .9];
        n = 17;
        b = firpm(n,f,a);
        y = filter(b,1,y);
    end

    if isfield([data.params],'fs')
        fs = data(itrial).params.fs;
    else
        warning('No "fs" field found; looking for sampling rate in field "sr".');
        fs = data(itrial).params.sr;
    end
    
    % if trial data exists, load event params and overwrite default params
    savefile = fullfile(dataPath,trialfolder,sprintf('%d.mat',itrial));
    if exist(savefile,'file')
        load(savefile);
        sigproc_params = trialparams.sigproc_params;
        if isfield(trialparams,'plot_params'), plot_params = trialparams.plot_params; else plot_params = []; end
        if isfield(trialparams,'event_params'), event_params = trialparams.event_params; else event_params = []; end
    elseif exist('wvp','var') % otherwise, use param file if it exists
        sigproc_params = wvp.sigproc_params;
        plot_params = wvp.plot_params;
        event_params = [];
    elseif exist('endstate','var') % otherwise, use last trial's params
        sigproc_params = endstate.sigproc_params;
        plot_params = endstate.plot_params;
        event_params = [];
    else % otherwise, get defaults
        sigproc_params = get_sigproc_defaults;
        plot_params = [];
        event_params = [];
    end
    
    % optionally overwrite figure position
    if ~isempty(figpos), plot_params.figpos = figpos; end
    
    %% call wave viewer
    endstate = wave_viewer(y,'fs',fs,'name',sprintf('trial(%d)',itrial), ...
        'nformants',2,'pitchlimits',pitchlimits,'sigproc_params',sigproc_params, ...
        'plot_params',plot_params,'event_params',event_params);
    
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
        
    if bSaveCheck, bSave = savecheck(savefile); else bSave = 1; end
    if bSave, save(savefile,'sigmat','trialparams'); end
    
    if strcmp(endstate.name,'end'), break; end
end

% save param file
sigproc_params = endstate.sigproc_params;
plot_params = endstate.plot_params;
bSave = savecheck(wvpfile);
if bSave, save(wvpfile,'sigproc_params','plot_params'); end