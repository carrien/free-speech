function expt = run_modelComp_expt(expt,bTestMode)
% RUN_MODELCOMP_EXPT - A simple AAF compensation experiment where F1 is
% shifted up on 20% of trials, F1 shifted down on 20%, and no shift 60%.
%
% Set bTestMode input argument to 1 to run a shortened version.

% v1 2023-10 - Chris Naber

%% Default arguments

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Set up general experiment parameters
expt.name = 'modelComp';
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
expt.audapterParams.bShift = 1;
expt.audapterParams.bRatioShift = 0;
expt.audapterParams.bMelShift = 1;
expt.audapterParams.fb = 3;          % set feedback mode to 3: speech + noise
expt.audapterParams.fb3Gain = 0.02;  % gain for noise waveform

%perturbation amount, in mels
shiftMag = 125;

% timing
expt.timing.stimdur = 1.9;          % time stim is on screen (in s)
expt.timing.interstimdur = .75;     % minimum time between stims (in s)
expt.timing.interstimjitter = .75;  % maximum extra time between stims (in s), ie, jitter
expt.timing.visualfbdur = 0.75;     % how long to show "speak louder" prompt (in s)

%set up duration feedback parameters
expt.durcalc.min_dur = .4;          % minimum allowable vowel duration (in s)
expt.durcalc.max_dur = .65;         % maximum allowable vowel duration (in s)
expt.durcalc.ons_thresh = 0.15;     % percentage of maximum amplitude for determining onset threshold
expt.durcalc.offs_thresh = 0.4;     % percentage of maximum amplitude for determining offset threshold

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
exptDur.allWords = randomize_wordOrder(length(exptDur.words), exptDur.ntrials);
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
expt.conds =      {'noShift' 'shiftDown' 'shiftUp'};
expt.shiftMag = 125;

if bTestMode
    expt.nblocks = 1;
else
    expt.nblocks = 6;
end

% Pseudorandomize stimuli like this: In each 15-trial block, each word gets
% an equal number of trials. Within a word, there are 2 perturbation
% trials, and 3 unperturbed trials. Within a word's 2 perturbation trials,
% there's 1 UP and 1 DOWN perturbation. No perturbation trials are adjacent, even across blocks.
nTrialsPerPert = 1;
uniquePerts = 2; % shiftUp, shiftDown
nTrialsPerNonpert = 3;
expt.ntrials_per_block = nwords*(nTrialsPerPert*uniquePerts + nTrialsPerNonpert); %aka 15 trials per block.
expt = randomize_stimuli(expt,nTrialsPerPert,nTrialsPerNonpert);

% Set up ntrials, coherence, and direction
expt.ntrials = expt.nblocks * expt.ntrials_per_block;

% Set up breaks
expt.breakFrequency = expt.ntrials_per_block * 2; %pp breaks every 2 blocks
% can also set break trials manually via expt.breakTrials

% set up duration feedback parameters
expt.bDurFB = ones(1,expt.ntrials); %yes, give participant feedback about vowel duration

% Set up shifts for the expt structure
expt.allShiftDirs = expt.allConds; 
expt.listShiftDirs = [expt.shiftDirs{expt.allConds}];
expt.allShiftNames = expt.allConds;   %in this experiment, shiftNames and conds are identical
expt.listShiftNames = expt.listConds;

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
