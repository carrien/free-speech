function [expt] = run_measureFormants_audapter(expt,fbMode)
% Template for altered feedback studies. Based on FUSP template but changed
% to work with Audapter.
%                   outputdir: directory where data is saved
%                   expt: expt params set up in wrapper function
%                   h_fig: figure handles for display

if nargin < 1, expt = []; end
if nargin < 2 || isempty(fbMode); fbMode = 3;end
if isfield(expt,'dataPath')
    outputdir = expt.dataPath;
else
    warning('Setting output directory to current directory: %s\n',pwd);
    outputdir = pwd;
end

% assign folder for saving trial data
% create output directory if it doesn't exist
trialdirname = 'temp_trials';
trialdir = fullfile(outputdir,trialdirname);
if ~exist(trialdir,'dir')
    mkdir(outputdir,trialdirname)
end

%% set up stimuli
% set experiment-specific fields (or pass them in as 'expt')
stimtxtsize = 200;

% set missing expt fields to defaults
expt = set_exptDefaults(expt);

%% set up audapter
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);

%set files for vowel tracking
if isfield(expt,'trackingFileName')
    if strcmp(expt.trackingFileLoc, 'experiment_helpers')
        ostFN = fullfile(get_gitPath('free-speech'), expt.trackingFileLoc, [expt.trackingFileName 'Working.ost']); 
        pcfFN = fullfile(get_gitPath('free-speech'), expt.trackingFileLoc, [expt.trackingFileName 'Working.pcf']); 
    else %it's in current-studies repo
        ostFN = fullfile(get_exptRunpath(expt.trackingFileLoc, [expt.trackingFileName 'Working.ost'])); 
        pcfFN = fullfile(get_exptRunpath(expt.trackingFileLoc, [expt.trackingFileName 'Working.pcf'])); 
    end
else
    ostFN = which('measureFormantsWorking.ost');
    pcfFN = which('measureFormantsWorking.pcf');
end
check_file(ostFN);
check_file(pcfFN);
Audapter('ost', ostFN, 0);
Audapter('pcf', pcfFN, 0);

% set audapter params
p = getAudapterDefaultParams(expt.gender); % get default params
p.bShift = 0;
if isfield(expt,'audapterParams') && isfield(expt.audapterParams,'nLPC')
    p.nLPC = expt.audapterParams.nLPC;
end

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = fbMode;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

AudapterIO('init', p);

%% run experiment
% setup figures
h_fig = setup_exptFigs; 
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;

h_sub = get_subfigs_audapter(h_fig(ctrl),1);
adjustButton = add_adjustOstButton(h_fig); % For adjusting OSTs mid-run
% give instructions and wait for keypress
h_ready = draw_exptText(h_fig,.5,.5,expt.instruct.introtxt,expt.instruct.txtparams);
pause
delete_exptText(h_fig,h_ready)

% run trials
trials2run = 1:expt.ntrials;
if expt.isRestart
    trials2run = trials2run(trials2run >= expt.startTrial);
end
pause(1)
for itrial = 1:length(trials2run)  % for each trial
    bGoodTrial = 0;
    while ~bGoodTrial
        % pause if 'p' is pressed
        if get_pause_state(h_fig,'p')
            pause_trial(h_fig);
        end
        if get_pause_state(h_fig,'a') % For adjusting OSTs mid-run
            adjustOsts(expt, h_fig);
        end

        % set trial index
        trial_index = trials2run(itrial);

        % plot trial number in experimenter view
        cla(h_sub(1))
        ctrltxt = sprintf('trial: %d/%d, cond: %s',trial_index,expt.ntrials,expt.listConds{trial_index});
        h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center');

        % set text
        txt2display = expt.listStimulusText{trial_index};
        color2display = expt.colorvals{expt.allColors(trial_index)};

        % run trial in Audapter
        Audapter('reset'); %reset Audapter
        fprintf('starting trial %d\n',trial_index)
        Audapter('start'); %start trial

        fprintf('Audapter started for trial %d\n',trial_index)
        % display stimulus
        h_text(1) = draw_exptText(h_fig,.5,.5,txt2display, 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
        pause(expt.timing.stimdur);

        % stop trial in Audapter
        Audapter('stop');
        fprintf('Audapter ended for trial %d\n',trial_index)
        % get data
        data = AudapterIO('getData');

        % plot shifted spectrogram  
        subplot_expt_spectrogram(data, p, h_fig, h_sub)
        % For adjusting OSTs mid-run
        subjOstParams = get_ost('experiment_helpers', 'measureFormants', 'full', 'working'); 
        data.subjOstParams = subjOstParams; 
        data.bChangeOst = 0; 

        %plot amplitude and ost tracking
        bGoodTrial = check_rmsThresh(data,[],h_sub(3), expt.amplcalc);

        % clear screen
        delete_exptText(h_fig,h_text)
        clear h_text

        if ~bGoodTrial && itrial > 9
            h_text = draw_exptText(h_fig,.5,.2,'Please speak a little louder','FontSize',40,'HorizontalAlignment','center','Color','y');
            pause(1)
            delete_exptText(h_fig,h_text)
            clear h_text
        end
        % add intertrial interval + jitter
        pause(expt.timing.interstimdur + rand*expt.timing.interstimjitter);

        % save trial
        trialfile = fullfile(trialdir,sprintf('%d.mat',trial_index));
        save(trialfile,'data')

        % clean up data
        clear data
        
    end
    % display break text
    if itrial == length(trials2run)
        breaktext = sprintf('Thank you!\n\nPlease wait.');
        draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause(3);
    elseif any(expt.breakTrials == trial_index)
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',itrial,expt.ntrials);
        h_break = draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause
        delete_exptText(h_fig,h_break)
        pause(1)
    end
     
end

%% write experiment data and metadata
% collect trials into one variable
alldata = struct;
fprintf('Processing data\n')
for i = 1:trials2run(end)
    load(fullfile(trialdir,sprintf('%d.mat',i)))
    names = fieldnames(data);
    for j = 1:length(names)
        alldata(i).(names{j}) = data.(names{j});
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

%% close figures
close(h_fig)
