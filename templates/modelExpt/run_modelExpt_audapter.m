function [expt] = run_modelExpt_audapter(expt, conds2run)
% Sister function of run_modelExpt_expt. Shows words on screen and records
% with Audapter.
%
% THIS IS NOT A REAL EXPERIMENT. For more info, see run_modelExpt_expt.

if nargin < 1, error('Need expt file to run this function'); end
if nargin < 2, conds2run = expt.conds; end

% assign folder for saving trial data
    %CONV: While the _audapter function is running, we save data from
    %individual trials as individual files in a temporary folder. When all
    %the trials are completed, we compile all those trials into data.mat.
    %Each row in data.mat then represents the data from a single trial.
trialdirname = 'temp_trials';
outputdir = expt.dataPath;
trialdir = fullfile(outputdir, trialdirname);
if ~exist(trialdir, 'dir')
    mkdir(trialdir)
end

% stimulus text font size
stimtxtsize = 150;

% set missing expt fields to defaults and save
    %[This is just in case someone runs this code without the wrapper
    %function (run_xx_expt). 
expt = set_exptDefaults(expt);
save(fullfile(outputdir,'expt.mat'), 'expt');

%find trial #'s to run
    %[ If MATLAB crashes during your experiment, `restart_expt.m` can look
    %at your temp data folder and figure out where you left off. It will
    %also set the flag expt.isRestart. If no crash, this code block assumes
    %you want to run all trials in the conditions listed in conds2run.
firstCond = conds2run{1};
lastCond = conds2run{end};
if expt.isRestart
    firstTrial = expt.startTrial;
else
    firstTrial = expt.inds.conds.(firstCond)(1);
end
lastTrial = expt.inds.conds.(lastCond)(end);

%% setup for audapter

    %[ Audapter has 2 methods of formant/pitch shifting. We are doing a
    % uniform F1 shift up, and the perturbation will be "on" during the
    % entire trial. The other method turns on and off the perturbation at
    % specific moments, as controlled by OST and PCF settings. These lines
    % turn off the OST and PCF settings.
Audapter('ost', '', 0);     % nullify online status tracking
Audapter('pcf', '', 0);     % nullify pert config files 

    %[ Audapter has a LOT of parameters. For any single experiment, we're
    %probably only changing a few from the default values. So, first we get
    %all of Audapter's default parameters and put them in a variable `p`.
    %Then if there are other things we want to change, we do so. 
    %(Sometimes we've already calculated some values and put them in
    %expt.audapterParams, in which case we integrate those with `p`.)
p = getAudapterDefaultParams(expt.gender); % get default params
% overwrite selected params with experiment-specific values
if isfield(expt, 'audapterParams')
    p = add2struct(p, expt.audapterParams);
end

audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);

p.bShift = 1; %set to 1 if you want to implement a formant shift
p.bRatioShift = 0; % set to 0 if you are using a shift in Hz or mels. Set to 1 if the shift is a ratio of the current formant value (e.g. 1.3*current value).
p.bMelShift = 1; %set to 0 if you are specifying the shift in Hz. Set to 1 if you are specifying the shift in mels.
p.bPitchShift = 0; % Set to 1 if using time warping or a pitch perturbation

% set noise
    %[ For many experiments, we mix the altered feedback with speech-shaped
    %noise to mask any air or bone conduction of the viridical feedback signal.
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = 3;           % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

expt.audapterParams = p;

%% initialize Audapter
AudapterIO('init', p);

%% run experiment

% set up figures
    %[ This section sets up the windows which display info to you and the
    %participant during the experiment. Since these figures don't need to
    %be speedy, we just make figures in Matlab instead of [[Psychtoolbox]].
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
h_sub = get_subfigs_audapter(h_fig(ctrl),1);

% For experiments using Audapter's OST and PCF files to control
% perturbations, un-comment the below line to add an "adjust OSTs" button
% to the top of the experimenter's monitoring figure (Figure 2).
% add_adjustOstButton(h_fig, {'settings'});

% give instructions and wait for keypress
h_ready = draw_exptText(h_fig,.5,.5, expt.instruct.introtxt, expt.instruct.txtparams);
pause
delete_exptText(h_fig,h_ready)

pause(1)

    %[ This is the big `for` loop where the experiment "actually" happens:
    %stimuli are presented and the participant's speech is recorded.
for itrial = firstTrial:lastTrial
    bGoodTrial = 0;
        %[ We use `bGoodTrial` to see if the participant responded to the
        %stimulus. If they didn't, re-do that same trial. You may not want
        %to use this for every experiment.
    while ~bGoodTrial
        % pause if 'p' is pressed
        if get_pause_state(h_fig,'p')
            pause_trial(h_fig);
        end

        % plot trial number in experimenter view
        cla(h_sub(1))
        ctrltxt = sprintf('trial: %d/%d, cond: %s',itrial,expt.ntrials,expt.listConds{itrial});
        ctrltxt = regexprep(ctrltxt, '_', '\\_'); % fix formatting if condition has underscore
        h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center'); %#ok<NASGU>

        % set text
        txt2display = expt.listStimulusText{itrial};
        color2display = expt.colorvals{expt.allColors(itrial)};

        % set new perturbation
        p.pertAmp = expt.shiftMags(itrial) * ones(1, 257);
        p.pertPhi = expt.shiftAngles(itrial) * ones(1, 257);
        Audapter('setParam','pertAmp',p.pertAmp)
        Audapter('setParam','pertPhi',p.pertPhi)

        % run trial in Audapter
            %[ Audapter directly accesses the microphone, bypassing MATLAB.
            %It works that way because Audapter is a [[MEX file]], written
            % in the C++ language. This helps Audapter reduce latency.
        Audapter('reset'); %reset Audapter
        Audapter('start'); %start trial

        fprintf('Audapter started for trial %d\n',itrial)
        % display stimulus
        h_text(1) = draw_exptText(h_fig,.5,.5,txt2display, 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
            %[ `pause` for as long as the trial duration should be, between
            %Audapter('start') and Audapter('stop')
        pause(expt.timing.stimdur);

        % stop trial in Audapter
        Audapter('stop');
        fprintf('Audapter ended for trial %d\n',itrial)

        % get data from Audapter
        data = AudapterIO('getData');

        % plot shifted spectrogram
        subplot_expt_spectrogram(data, p, h_fig, h_sub)
        
        %check if pp spoke above amplitude threshold
        bGoodTrial = check_rmsThresh(data, expt.amplcalc, h_sub(3));
        
        % clear screen
        delete_exptText(h_fig,h_text)
        clear h_text

            %[ Our determination of something being a good trial is if
            %it was loud enough. More specifically, if the average
            %amplitude for 100 ms surrounding the peak amplitude was above
            %a certain threshold. Thus, if the trial wasn't good, we
            %prompt the participant, "speak louder." If your experiment
            %defines bGoodTrial differently (for example, participant's
            %response was too short), you should prompt them differently.
        if ~bGoodTrial
            h_text = draw_exptText(h_fig,.5,.2,'Please speak a little louder','FontSize',40,'HorizontalAlignment','center','Color','y');
            pause(1)
            delete_exptText(h_fig,h_text)
            clear h_text
        end
        
        % add intertrial interval + jitter
            %[ In the _expt function we called `rng('shuffle')`. That
            %"good" [[RANDOMNESS]] carries over to these `rand` calls
        pause(expt.timing.interstimdur + rand * expt.timing.interstimjitter);

        % save trial
        trialfile = fullfile(trialdir, sprintf('%d.mat',itrial));
        save(trialfile,'data')

        % clean up data
        clear data
    end
    % display break text
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

%% compile trials into data.mat. Save metadata.
if any(ismember(conds2run, expt.conds{end}))
    %[ Once the last condition has been run, we compile all the data.
    %During the experiment, each trial was saved as an individual file
    %named [trial_num].mat the temp_trials folder. Data for each trial
    %gets loaded into a separate row in the data.mat file. Then we delete
    %the temp_trials directory, which isn't needed anymore.
    
    % collect trials into one variable
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

%% close figures
close(h_fig)


end %EOF
