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
outputdir = fullfile(expt.dataPath, trialdirname);
if ~exist(outputdir, 'dir')
    mkdir(outputdir, trialdirname)
end

%set RMS threshold for deciding if a trial is good or not
rmsThresh = 0.04;
stimtxtsize = 200;

% set missing expt fields to defaults and save
    %[This is just in case someone runs this code without the wrapper
    %function (run_xx_expt). 
expt = set_exptDefaults(expt);
save(fullfile(outputdir,'expt.mat'), 'expt');

%find trial #'s to run through for this iteration of modelExpt_audapter
    %[ These two lines might look scary; they're more for the "template"
    %crowd than the "tutorial" crowd. You shouldn't need to change them,
    %and if you do, the comment tells you what your code needs to do to
    %replace them.
firstTrial = find(expt.allConds == find(strcmp(expt.conds, conds2run{1})), 1, 'first');
lastTrial = find(expt.allConds == find(strcmp(expt.conds, conds2run{end})), 1, 'last');

%% setup for audapter

helpersDir = fullfile(get_gitPath, 'current-studies', 'experiment_helpers');
    %[ For modelExpt, we use very simple [[OST and PCF files]]
    %that only try to find landmarks for vowel onset and vowel offset.
ostFN = fullfile(helpersDir, 'measureFormants.ost');
pcfFN = fullfile(helpersDir, 'measureFormants.pcf');
check_file(ostFN);
check_file(pcfFN);
Audapter('ost', ostFN, 0);
Audapter('pcf', pcfFN, 0);

    %[ These settings probably won't change from experiment to experiment.
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
sRate = 48000;  % Hardware sampling rate (before downsampling)
downFact = 3; % For most studies, we will sample downsample the data by 3 for a final sampling rate of 16 kHz.
frameLen = 96/downFact;  % Before downsampling

Audapter('deviceName', audioInterfaceName);
Audapter('setParam', 'sRate', sRate / downFact, 0);
Audapter('setParam', 'downFact', downFact, 0);
Audapter('setParam', 'frameLen', frameLen, 0);

    %[ Audapter has a LOT of parameters. For any single experiment, we're
    %probably only changing a few from the default values. So, first we get
    %all of Audapter's default parameters and put them in a variable `p`.
    %Then if there are other things we want to change, we do so. (Sometimes
    %we've already calculated some values and put them in
    %expt.audapterParams, in which case we integrate those with `p`.
p = getAudapterDefaultParams(expt.gender); % get default params
% overwrite selected params with experiment-specific values:
if isfield(expt, 'audapterParams')
    p = add2struct(p, expt.audapterParams);
end
p.bPitchShift = 0; % Set to 1 if using time warping or a pitch perturbation
p.downFact = downFact;
p.sr = sRate / downFact;
p.frameLen = frameLen;

    % TODO are these conflicting with using OSTs?
    % TODO add more Audapter descriptions
p.bShift = 1; %set to 1 if you want to implement a formant shift
p.bRatioShift = 0; % set to 0 if you are using a shift in Hz or mels. Set to 1 if the shift is a ratio of the current formant value (e.g. 1.3*current value).
p.bMelShift = 1; %set to 0 if you are specifying the shift in Hz. Set to 1 if you are specifying the shift in mels.

% set noise
    %[ For many experiments, we play white noise in the background. That
    %way, participants only hear their (often perturbed) speech through the
    %headphones.
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = 3;          % set feedback mode to 3: speech + noise
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

% give instructions and wait for keypress
h_ready = draw_exptText(h_fig,.5,.5, expt.instruct.introtxt, expt.instruct.txtparams);
pause
delete_exptText(h_fig,h_ready)

pause(1)

    %[ Like the below section, there's often a point in the experiment
    %where there's a big `for` loop and the experiment "actually" happens.
    %This is when stimuli are presented and responses are recorded.
for itrial = firstTrial:lastTrial
    bGoodTrial = 0;
        %[ We use `bGoodTrial` to see if the participant responded to the
        %stimulus. If they didn't, re-do that same trial. You may not want
        %to use this for evey experiment.
    while ~bGoodTrial
        % pause if 'p' is pressed
        if get_pause_state(h_fig,'p')
            pause_trial(h_fig);
        end

        % plot trial number in experimenter view
        cla(h_sub(1))
        ctrltxt = sprintf('trial: %d/%d, cond: %s',itrial,expt.ntrials,expt.listConds{itrial});
        h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center');

        % set text
        txt2display = expt.listWords{itrial};
        color2display = expt.colorvals{expt.allColors(itrial)};

        % set new perturbation
            %[ In modelExpt, nothing is different between the different
            %conditions (baseline, ramp, hold). This section is a
            %placeholder for where you would modify settings that change
            %between trials or between conditions. As an example, you can
            %look at `run_vsaAdapt_audapter` and `run_vsaAdapt2_expt`

        % run trial in Audapter
            %[ Audapter works by getting a direct feed of the microphone
            %input between when we say 'start' and 'stop'. During that
            %time, the mic signal *is not* getting sent to Matlab, since
            %Audapter is a [[MEX file]].
        Audapter('reset'); %reset Audapter
        fprintf('starting trial %d\n',itrial)
        Audapter('start'); %start trial

        fprintf('Audapter started for trial %d\n',itrial)
        % display stimulus
        h_text(1) = draw_exptText(h_fig,.5,.5,txt2display, 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
            %[ This `pause` call tells Matlab how long to wait between
            %telling Audapter to 'start' and 'stop'.
        pause(expt.timing.stimdur);

        % stop trial in Audapter
        Audapter('stop');
        fprintf('Audapter ended for trial %d\n',itrial)
        % get data
            %[ This call asks Audapter to send data to Matlab about what
            %happened between the last 'start' and 'stop' calls.
        data = AudapterIO('getData');

        % plot shifted spectrogram
        figure(h_fig(ctrl))
        subplot(h_sub(2))
        show_spectrogram(data.signalIn, data.params.sr, 'noFig');
        tAxis = 0 : p.frameLen : p.frameLen * (size(data.fmts, 1) - 1);
        plot(tAxis/data.params.sr,data.fmts(:, 1 : 2), 'c','LineWidth',3);
        plot(tAxis/data.params.sr,data.sfmts(:, 1 : 2), 'm','LineWidth',1.5);
        
        %check if good trial (ie, heard pt speak)
        bGoodTrial = check_rmsThresh(data, rmsThresh, h_sub(3));
        
        % clear screen
        delete_exptText(h_fig,h_text)
        clear h_text

            %[ For modelExpt, our determination of something being a good
            %trial is whether the microphone signal rose above a certain
            %threshold (`rmsThresh`). Thus, if the trial wasn't good, we
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
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',itrial,length(trials2run));
        h_break = draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause
        delete_exptText(h_fig,h_break)
    end
    
end

%% compile trials into data.mat. Save metadata.
if any(ismember(conds2run, expt.conds{end}))
    %[ Once the last condition has been run, we compile all the data.
    %During the experiment, each trial was saved as an individual file
    %named [trial_num].mat the temp_trials folder. Data for each trial
    %gets loaded into a separate row in the data.mat file. Then we delete
    %the no-longer-needed temp_trials directory.
    
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

end

