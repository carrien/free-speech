ft_defaults;

snum = 3;

%% MEG
% read MEG .fif data
megPath = getMegSubjPath('aphSIS',snum);
fiffile = fullfile(megPath,sprintf('aphsis%02d_tsss_mc.fif',snum));
hdr = ft_read_header(fiffile);
dat = ft_read_data(fiffile);

% get sourcespace
sourcespace = ft_read_headshape(fiffile, 'format', 'neuromag_fif');
sourcespace = ft_convert_units(sourcespace, 'mm');
%sourcespace = ft_transform_geometry(T, sourcespace);

%% experiment design
% define speak trials
cfg = [];
cfg.trialdef.prestim = 0.7;                 % in seconds
cfg.trialdef.poststim = 0.4;                % in seconds
cfg.trialdef.eventtype = 'STI101';
cfg.trialdef.eventvalue = 1:3;                % trigger value
cfg.dataset = fiffile;
cfg = ft_definetrial(cfg);

cfg.bpfilter = 'yes';
cfg.bpfreq = [4 40];                % HPF at 4 Hz; LPF at 40 Hz
cfg.baselinewindow = [-0.7 -0.4];   % set baseline window
cfg.demean = 'yes';
%cfg.detrend = 'yes';
data_speak = ft_preprocessing(cfg);

% define listen trials
cfg = [];
cfg.trialdef.prestim = 0.7;                 % in seconds
cfg.trialdef.poststim = 0.4;                % in seconds
cfg.trialdef.eventtype = 'STI101';
cfg.trialdef.eventvalue = 4:6;                % trigger value
cfg.dataset = fiffile;
cfg = ft_definetrial(cfg);

cfg.bpfilter = 'yes';
cfg.bpfreq = [4 40];                % HPF at 4 Hz; LPF at 40 Hz
cfg.baselinewindow = [-0.7 -0.4];   % set baseline window
cfg.demean = 'yes';
%cfg.detrend = 'yes';
data_listen = ft_preprocessing(cfg);

% avg
cfg = [];
timelock_speak = ft_timelockanalysis(cfg,data_speak);
timelock_listen = ft_timelockanalysis(cfg,data_listen);


%% MRI
% read MRI .mgz data
fsdir = fullfile(getenv('SUBJECTS_DIR'),sprintf('s%02d',snum));
mrifile = fullfile(fsdir,'mri','T1.mgz');
mri = ft_read_mri(mrifile);

cfg           = [];
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri);
%save segmentedmri segmentedmri
disp(segmentedmri)

cfg = [];
cfg.method='singleshell';
vol = ft_prepare_headmodel(cfg, segmentedmri);
%save vol vol
disp(vol)

%% coreg
vol = ft_convert_units(vol,'cm');
sens = ft_read_sens(fiffile);

figure
ft_plot_sens(sens, 'style', '*b');
hold on
ft_plot_vol(vol);

cfg = [];
cfg.method='singleshell';
vol = ft_prepare_headmodel(cfg, segmentedmri);
%save vol vol
disp(vol)
