function [] = overwrite_tg_events(dataPath,trialnums,tgdir,trialdir)
%OVERWRITE_TG_EVENTS Overwrite existing events with those from MFA textgrid
%output.
    %OVERWRITE_TG_EVENTS(DATAPATH, TRIALNUMS, TGDIR, TRIALDIR)
    %Given a DATAPATH containing a TRIALDIR folder (output from tracking
    %with waverunner, default 'trials'), a set of TRIALNUMS to consider 
    %(default is all trials), and a TGDIR containing output from the forced 
    % alinger (probably 'PostAlignment'), this function will check to see
    % if existing events are from MFA textgrids and if not, it will
    % attempt to overwrite any event information with those from the
    % textgrid output of the forced aligner.
    
%% Handle default arguments
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialnums = []; end
if nargin < 3 || isempty(tgdir), tgdir = 'PostAlignment'; end
if nargin < 4 || isempty(trialdir), trialdir = 'trials'; end

%% Get user input for which trials should be considered 
%(similar to audioGUI/waverunner)
trialdir = fullfile(dataPath, trialdir);

if isempty(trialnums)
    reply = input('Start trial? [1]: ','s');
    if isempty(reply), reply = '1'; end
    startTrial = sscanf(reply,'%d');
    W = what(trialdir);
    matFiles = [W.mat];
    trials2track = startTrial:length(matFiles);
else
    trials2track = trialnums;
end

% Loop over the trials provided,
for itrial = trials2track
    savefile = fullfile(trialdir,sprintf('%d.mat',itrial)); %Trial file
    tgFilename = sprintf('AudioData_%d.TextGrid',itrial); %Textgrid for that trial
    tgPath =  fullfile(dataPath,tgdir,tgFilename); %Path to textgrid file
    
    %Load the trial file if it exists, otherwise continue the loop over the
    %trials.
    if exist(savefile,'file')
        load(savefile);
        run_get_tgs = 1; %assume we will replace events with those from textgrids
        
        %Load variables from trial file.
        if isfield(trialparams,'sigproc_params'), sigproc_params = trialparams.sigproc_params; else, sigproc_params = [];end
        if isfield(trialparams,'plot_params'), plot_params = trialparams.plot_params; else, plot_params = []; end
        
        %Load event information
        if isfield(trialparams,'event_params'), event_params = trialparams.event_params;
            %If the trial has not been marked as bad
            if isfield(event_params,'is_good_trial')
                if event_params.is_good_trial == 1    
                    %% if existing user events do not contain uev, skip this trial
                    if isfield(trialparams.event_params,'user_event_names')
                        if ~isempty(event_params.user_event_names)
                            %loop over event names
                            for ev = 1:length(event_params.user_event_names)
                                if strncmp(event_params.user_event_names(ev),'uev',3)
                                    continue
                                else
                                    warning('%s already contains events from MFA, skipping...',savePath)
                                    %TODO: is it possible that events could
                                    %be placed that do not contain UEV but
                                    %were not from the aligner?
                                    run_get_tgs = 0;
                                    break
                                end
                            end
                            
                        end
                    end             
                else %If it's a bad trial, set event_params to empty.
                    event_params = [];
                end
                
                %% There is an existing textgrid file and run_get_tgs is flagged
                %(we want to overwrite existing events with info from the
                %textgrid file)
                if (exist(tgPath,'file') && (run_get_tgs == 1))
                    [tg_user_event_times, tg_user_event_names] = get_uev_from_tg_mpraat(tgPath);
                    %clear event times and names
                    if ~isfield(event_params,'user_event_times')
                        event_params.user_event_times = [];
                        event_params.user_event_names = [];
                    end
                    %fill event params with new information
                    event_params.user_event_times = [event_params.user_event_times, tg_user_event_times];
                    event_params.user_event_names = [event_params.user_event_names, tg_user_event_names];
                    
                    %re-establish and overwrite the trial file
                    trialparams.sigproc_params = sigproc_params;
                    trialparams.plot_params = plot_params;
                    trialparams.event_params = event_params;
                    save(savefile,'trialparams')
                end
                
            end %End bad trial check
        % Provide a warning for these two cases, as the trial file and event params should exist.
        else
           warning('Event params do not exist for %s, skipping...',saveFile) 
        end 
    else
        warning('%s does not exist, skipping...',saveFile)
    end
    
end %END OF TRIAL LOOP

end %END OF FUNCTION
