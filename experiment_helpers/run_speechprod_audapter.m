function [expt] = run_speechprod_audapter(outputdir,expt)
% Template for altered feedback studies. Based on FUSP template but changed
% to work with Audapter. 
%                   outputdir: directory where data is saved
%                   expt: expt params set up in wrapper function
%                   h_fig: figure handles for display

if nargin < 1 || isempty(outputdir), outputdir = pwd; end
if nargin < 2, expt = []; end

% create output directory if it doesn't exist
trialdir = fullfile(outputdir,'trials');
if ~exist(trialdir,'dir')
    mkdir(outputdir,'trials')
end 

%% set up stimuli
% set experiment-specific fields (or pass them in as 'expt')
expt.name = 'speechprod';
stimtxtsize = 200;

% set missing expt fields to defaults
expt = merge_exptDefaults(expt);

%% set up audapter
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);
Audapter('ost', '', 0);     % nullify online status tracking/
Audapter('pcf', '', 0);     % pert config files (use pert field instead)

% set audapter params
p = getAudapterDefaultParams(expt.gender); % get default params
% overwrite selected params with experiment-specific values:
p.bShift = 1;
p.bRatioShift = 0;
p.bMelShift = 1;

% set noise
noiseWavFN = 'mtbabble48k.wav';
w = get_noiseSource(noiseWavFN,p);
p.datapb = w; % was: Audapter('setParam', 'datapb', w, 1);
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.3;   % gain for noise waveform

%% initialize Audapter
AudapterIO('init', p);

%% run experiment
% setup figures
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
h_sub = get_subfigs_audapter(h_fig(ctrl));

% give instructions and wait for keypress
h_ready = draw_exptText(h_fig,.5,.5,expt.instruct.introtxt,expt.instruct.txtparams);
pause
delete_exptText(h_fig,h_ready)

% run trials
for iblock = 1:expt.nblocks                 % for each block
    pause(1)
    for itrial = 1:expt.ntrials_per_block   % for each trial
        % pause if 'p' is pressed
        if get_pause_state(h_fig,'p')
%             pause_trial(h_fig);
            mag_shift = input('Enter shift in mels: ');
        end

        % set trial index    
        trial_index = (iblock-1).* expt.ntrials_per_block + itrial;
        
        % plot trial number in experimenter view
        cla(h_sub(1))
        ctrltxt = sprintf('trial: %d/%d, cond: %s',trial_index,expt.ntrials,expt.listConds{trial_index});
        h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center');
        
        % set new perturbation   
        p.pertAmp = expt.shiftMags(trial_index) * ones(1, 257);
        p.pertPhi = expt.shiftAngles(trial_index) * ones(1, 257);
        Audapter('setParam','pertAmp',p.pertAmp)
        Audapter('setParam','pertPhi',p.pertPhi) % I seem to remember you can set multiple params in one line -- test this
        
        % run trial in Audapter        
        Audapter('reset'); %reset Audapter
        Audapter('start'); %start trial
    
        % display stimulus
        txt2display = expt.listWords{trial_index};
        color2display = expt.colorvals{expt.allColors(trial_index)};
        h_text(1) = draw_exptText(h_fig,.5,.5,txt2display, 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
        pause(expt.timing.stimdur);
        
        % stop trial in Audapter
        Audapter('stop');
        
        % get data
        data = AudapterIO('getData'); 
        
        % plot duration feedback
        [h_dur,success] = plot_duration_feedback(h_fig(stim), data, expt.durcalc); % original line
        if isfield(expt,'success')
            expt.success(trial_index) = success;
        end
       
        CloneFig(h_fig(stim),h_fig(dup))

        % plot shifted spectrogram
        figure(h_fig(ctrl))
        subplot(h_sub(2))
        show_spectrogram(data.signalIn, data.params.sr, 'noFig');
        tAxis = 0 : p.frameLen : p.frameLen * (size(data.fmts, 1) - 1);
        plot(tAxis/data.params.sr,data.fmts(:, 1 : 2), 'b');
        plot(tAxis/data.params.sr,data.sfmts(:, 1 : 2), 'g');

        % pause for viewing duration feedback
        pause(expt.timing.visualfbdur);
        
        % clear screen
        delete_exptText(h_fig,[h_text h_dur])
        clear h_text h_dur 
        
        % add intertrial interval + jitter
        pause(expt.timing.interstimdur + rand*expt.timing.interstimjitter);
        
        % save trial
        trialfile = fullfile(trialdir,[num2str(trial_index) '.mat']);
        save(trialfile,'data')
    end
    
    % end of block: display break text
    if iblock < expt.nblocks
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',itrial,expt.ntrials);
    else
        breaktext = sprintf('Thank you!\n\nPlease wait.');
    end
    h_break = draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
    pause
    delete_exptText(h_fig,h_break)
    
end


%% write experiment data and metadata
alldata = struct;
for i = 1:expt.ntrials
    load(fullfile(trialdir,[num2str(i) '.mat']))
    names = fieldnames(data);
    for j = 1:length(names)
        alldata(i).(names{j}) = data.(names{j});
    end
end
clear data
data = alldata;
save(fullfile(outputdir,'data.mat'), 'data')
close(h_fig)
