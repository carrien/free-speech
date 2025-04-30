function [expt] = run_modelComp_audapter(expt)
% Companion function for modelComp
% Don't run this directly -- run your `run_xyz_expt` function instead.

if nargin < 1
    error('Must pass in valid expt variable from run_xyz_expt function.')
end
expt = set_exptDefaults(expt);

%%

if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end

% assign folder for saving trial data
% create output directory if it doesn't exist
trialdirname = 'temp_trials';
outputdir = expt.dataPath;
trialdir = fullfile(outputdir, trialdirname);
if ~exist(trialdir, 'dir')
    mkdir(trialdir)
end

%% set up stimuli
stimtxtsize = 150;

firstTrial = expt.startTrial; % defaults to 1
lastTrial = expt.ntrials;

%% set up audapter
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);

% set files for vowel tracking
Audapter('ost', '', 0); % nullify online status tracking
Audapter('pcf', '', 0); % nullify pert config files. We're using pert field instead

% set audapter params
p = getAudapterDefaultParams(expt.gender); % get default params
% overwrite selected params with experiment-specific values:
if isfield(expt, 'audapterParams')
    p = add2struct(p,expt.audapterParams);
end

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);

%% initialize Audapter
AudapterIO('init', p);

%% run experiment
% setup figures
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
h_sub = get_subfigs_audapter(h_fig(ctrl),1);
% add_adjustOstButton(h_fig, {'settings'});

% give instructions and wait for keypress
h_ready = draw_exptText(h_fig,.5,.5,expt.instruct.introtxt,expt.instruct.txtparams);
pause
delete_exptText(h_fig,h_ready)
pause(1)

% run trials
for itrial = firstTrial:lastTrial  % for each trial
    bGoodTrial = 0;
    while ~bGoodTrial
        % pause if 'p' is pressed
        if get_pause_state(h_fig,'p')
            pause_trial(h_fig);
        end
        if get_pause_state(h_fig,'e') % Pause for adjusting trial duration
            adjustments = {'trialdur' 'voweldur'};
            setting2change = askNChoiceQuestion('Change the trial duration (1) or vowel duration properties ie, min/max (2)?', [1 2], 0);
            adjustment = adjustments{setting2change};

            expt = adjust_experimentSettings(expt, h_fig, adjustment);
        end

        % plot trial number in experimenter view
        cla(h_sub(1))
        ctrltxt = sprintf('trial: %d/%d, cond: %s',itrial,expt.ntrials,expt.listConds{itrial});
        h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center'); %#ok<NASGU> 

        % set text
        txt2display = expt.listWords{itrial};
        color2display = expt.colorvals{expt.allColors(itrial)};

        % set new perturbation
        p.pertAmp = expt.shiftMags(itrial) * ones(1, 257);
        p.pertPhi = expt.shiftAngles(itrial) * ones(1, 257);
        Audapter('setParam','pertAmp',p.pertAmp)
        Audapter('setParam','pertPhi',p.pertPhi)

        % run trial in Audapter
        Audapter('reset'); %reset Audapter
        Audapter('start'); %start trial
        fprintf('Audapter started for trial %d\n',itrial)

        % display stimulus
        h_text(1) = draw_exptText(h_fig,.5,.5,txt2display, 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
        pause(expt.timing.stimdur);

        % stop trial in Audapter and get data
        Audapter('stop');
        fprintf('Audapter ended for trial %d\n',itrial)
        data = AudapterIO('getData');

        % plot shifted spectrogram
        subplot_expt_spectrogram(data, p, h_fig, h_sub);

        % check if participant spoke loud enough for amplitude to cross required threshold
        bGoodTrial = check_rmsThresh(data, expt.amplcalc, h_sub(3));
        subplot(h_sub(3))

        if ~bGoodTrial %first check if amplitude crossed threshold
            h_text(2) = draw_exptText(h_fig,.5,.2,'Please speak a little louder','FontSize',40,'HorizontalAlignment','center','Color','y');

            % pause for viewing duration feedback
            pause(expt.timing.visualfbdur);

            % clear screen
            delete_exptText(h_fig,h_text)
            clear h_text
        elseif expt.bDurFB(itrial) %plot duration feedback, if needed for this trial
            % plot duration feedback
            [h_dur,success] = plot_duration_feedback(h_fig(stim), data, expt.durcalc); % original line
            if isfield(expt,'success')
                expt.success(itrial) = success;
            end

            CloneFig(h_fig(stim),h_fig(dup))

            % pause for viewing duration feedback
            pause(expt.timing.visualfbdur);

            % clear screen
            delete_exptText(h_fig,[h_text h_dur])
            clear h_text h_dur
        else
            % clear screen
            delete_exptText(h_fig,h_text)
            clear h_text
        end

        % add intertrial interval + jitter
        pause(expt.timing.interstimdur + rand*expt.timing.interstimjitter);

        % save trial
        trialfile = fullfile(trialdir,sprintf('%d.mat',itrial));
        save(trialfile,'data')

        %clean up data
        clear data
    end
    if itrial == expt.ntrials
        breaktext = sprintf('Thank you!\n\nPlease wait.');
        draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause(3);
    elseif any(expt.breakTrials == itrial)
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',itrial,expt.ntrials);
        h_break = draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause
        delete_exptText(h_fig,h_break)
        pause(1);
    end
end

%% write experiment data and metadata
% collect trials into one variable
if itrial == expt.ntrials
    alldata = struct;
    fprintf('Processing data\n')
    for i = 1:expt.ntrials
        trialfile = fullfile(trialdir,sprintf('%d.mat',i));
        if exist(trialfile,'file')
            load(trialfile,'data')
            names = fieldnames(data);
            for j = 1:length(names)
                alldata(i).(names{j}) = data.(names{j});
            end
        else
            warning('Trial %d not found.',i)
        end
    end

    % save data
    fprintf('Saving data... ')
    clear data
    data = alldata;
    save(fullfile(outputdir,'data.mat'), 'data')
    fprintf('saved.\n')

    % save expt
    fprintf('Saving expt... ')
    save(fullfile(outputdir,'expt.mat'), 'expt')
    fprintf('saved.\n')

    % remove temp trial directory
    fprintf('Removing temp directory... ')
    rmdir(trialdir,'s');
    fprintf('done.\n')
end

close(h_fig)


end %EOF
