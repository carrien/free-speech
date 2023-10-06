function expt = run_modelComp_expt(expt,bTestMode)
% RUN_MODELCOMP_EXPT - A simple AAF compensation experiment where F1 is
% shifted up on 20% of trials, F1 shifted down on 20%, and no shift 60%.
%
% Set bTestMode input argument to 1 to run a shortened version.
%
% Based around run_cerebAAF_expt and run_modelExpt_expt

% v1 2023-10 - Chris Naber

%% Default arguments

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Set up general experiment parameters
expt.name = 'modelComp';
expt.trackingFileLoc = 'experiment_helpers'; % Where the OST/PCF files are kept (for audapter_viewer)
expt.trackingFileName = 'measureFormants'; % What the files are called (does not include Working/Master)
refreshWorkingCopy(expt.trackingFileLoc,expt.trackingFileName);
if ~isfield(expt,'snum'), expt.snum = get_snum; end
expt.dataPath = get_acoustSavePath(expt.name,expt.snum);
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end

if ~isfield(expt,'gender'), expt.gender = get_height; end       % vocal tract length or gender correlate for LPC Order

% In other experiments, instead of assuming LPC, we collect some
%   speech samples and allow the experimenter to evaluate different LPCs on
%   that dataset. For simplicity here, LPC is just set arbitrarily.
if strcmp(expt.gender, 'male')
    expt.audapterParams.nLPC = 17;
else
    expt.audapterParams.nLPC = 15;
end

%perturbation amount, in mels
shiftMag = 125;

% timing
expt.timing.stimdur = 1.9;         % time stim is on screen, in seconds
expt.timing.interstimdur = .75;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .75; % maximum extra time between stims (jitter)
expt.timing.visualfbdur = 0.75; 

%set up duration feedback parameters
expt.durcalc.min_dur = .4; % set_exptDefaults normally sets to .25
expt.durcalc.max_dur = .65;
expt.durcalc.ons_thresh = 0.15;
expt.durcalc.offs_thresh = 0.4;

%% Set up duration practice
exptDur = expt;
exptDur.session = 'dur'; 
exptDur.dataPath = fullfile(expt.dataPath,exptDur.session);
if ~exist(exptDur.dataPath, 'dir')
    mkdir(exptDur.dataPath)
end
exptDur.ntrials = 6;

exptDur.shiftMags   = zeros(1,exptDur.ntrials);
exptDur.shiftAngles = zeros(1,exptDur.ntrials);

exptDur.words = {'head' 'dead' 'Ted'};
exptDur.allWords = mod(0:exptDur.ntrials-1, numel(exptDur.words)) + 1;
exptDur.listWords = exptDur.words(exptDur.allWords);

exptDur.conds = {'noShift'};
exptDur.allConds = ones(1, exptDur.ntrials);
exptDur.listConds = exptDur.conds(exptDur.allConds);

% set up duration feedback parameters
exptDur.bDurFB = ones(1,exptDur.ntrials); % 1 x ntrials vector

exptDur = set_exptDefaults(exptDur);

exptfile = fullfile(exptDur.dataPath,'expt.mat');
dur.expt = exptDur;
save(exptfile, '-struct', 'dur')
fprintf('Saved exptDur file: %s.\n',exptfile);

%% Set up compensation experiment
% stimuli and vowel list
expt.words = {'head' 'dead' 'Ted'}; 
nwords = length(expt.words);
[vowels,~,ivowels] = unique(txt2arpabet(expt.words));
if length(vowels) == length(ivowels), vowels = vowels(ivowels); end
expt = set_missingField(expt,'vowels',vowels);

expt.shiftDirs = {0 -1 1};
expt.shiftNames = {'noShift' 'shiftDown' 'shiftUp'};
expt.shiftMag = 125;
expt.conds = {'noShift' 'shiftDown' 'shiftUp'};

if bTestMode
    expt.nblocks = 1;
else
    expt.nblocks = 6;
end

expt.ntrials_per_block = nwords*(2+3); %aka 15 trials per block.

% Number of trials that don't receive perturbation
if bTestMode 
    nBaseline = 1;
else 
    nBaseline = 15;
end

% Pseudorandomize stimuli like this: In each 15-trial block, each word gets
% an equal number of trials. Within a word, there are 2 perturbation
% trials, and 3 unperturbed trials. Within a word's 2 perturbation trials,
% there's 1 UP and 1 DOWN perturbation. No perturbation trials are adjacent, even across blocks.
expt = randomize_stimuli(expt,1,3,nBaseline);

% Set up ntrials, coherence, and direction
expt.ntrials = expt.nblocks * expt.ntrials_per_block;

% Set up breaks, expt.ntrials must be divisible by break frequency
breakfrequency = expt.ntrials_per_block * 2;
expt.breakTrials = breakfrequency:breakfrequency:expt.ntrials;  %pp breaks after baseline; then, every 2 blocks

% set up duration feedback parameters
expt.bDurFB = ones(1,expt.ntrials); %yes, give participant feedback about vowel duration

% Set up shifts for the expt structure
expt.allShiftDirs = expt.allConds; 
expt.listShiftDirs = [expt.shiftDirs{expt.allConds}];
expt.allShiftNames = expt.allShiftDirs;
expt.listShiftNames = expt.shiftNames(expt.allShiftNames);

expt.shiftMags = shiftMag*expt.listShiftDirs;

% set missing expt fields to defaults
expt = set_exptDefaults(expt);

%% save expt
exptfile = fullfile(expt.dataPath,'expt.mat');
bSave = savecheck(exptfile);
if bSave
    save(exptfile, 'expt')
    fprintf('Saved expt file: %s.\n',exptfile);
end

%% run experiment
%% run duration training
duration_response = askNChoiceQuestion('Run duration practice?', {'run' 'skip'});
if strcmp(duration_response,'skip')
    bRunTraining = 0;
else
    bRunTraining = 1;
end

while bRunTraining
    exptDur.success = zeros(1,exptDur.ntrials);
    exptDur = run_modelComp_audapter(exptDur);
    rerun_response = askNChoiceQuestion(sprintf('Participant was successful on: %d/%d trials. Redo training?',sum(exptDur.success),length(exptDur.success)), {'redo' 'move on'});
    if strcmp(rerun_response,'move on')
        bRunTraining = 0;
    end
end

%% run compensation experiment
expt = run_modelComp_audapter(expt);
exptfile = fullfile(expt.dataPath,'expt.mat');
fprintf('Saved expt file: %s.\n',exptfile);


end %EOF