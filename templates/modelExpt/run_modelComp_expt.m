function expt = run_modelComp_expt(expt,bTestMode)
% RUN_MODELCOMP_EXPT - A simple AAF compensation experiment where F1 is
% shifted up on 20% of trials, F1 shifted down on 20% of trials, and
% no shift on 60% of trials.
%
% Set bTestMode input argument to 1 to run a shortened version.

% v1 2023-10 - Chris Naber

%% Default arguments

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Set up general experiment parameters
expt.name = 'modelComp';
expt.bTestMode = bTestMode;
if ~isfield(expt,'snum'), expt.snum = get_snum; end
expt.dataPath = get_acoustSavePath(expt.name,expt.snum);
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end

if ~isfield(expt,'gender'), expt.gender = get_height; end       % vocal tract length or gender correlate for LPC Order

%% Set LPC order in pre-experiment speaking phase
if ~expt.bTestMode
    bRunLPCcheck = 1;
else
    bRunLPCcheck = askNChoiceQuestion('[Test mode only] Run LPC check pretest phase (1), or skip it (0)? ', [1 0]);
end
if bRunLPCcheck
    [expt, ~] = run_checkLPC(expt, exptPre);
end

%% More expt settings
expt.audapterParams.bShift = 1;
expt.audapterParams.bRatioShift = 0;
expt.audapterParams.bMelShift = 1;
expt.audapterParams.fb = 3;          % set feedback mode to 3: speech + noise
expt.audapterParams.fb3Gain = 0.02;  % gain for noise waveform

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

exptDur.words = {'head' 'dead' 'Ted'};
nwords = length(exptDur.words);
exptDur.ntrials = nwords * 4; % arbitrary
exptDur.allWords = randomize_wordOrder(length(exptDur.words), exptDur.ntrials);
exptDur.listWords = exptDur.words(exptDur.allWords);

exptDur.shiftMags   = zeros(1,exptDur.ntrials);
exptDur.shiftAngles = zeros(1,exptDur.ntrials);

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
expt.shiftMag = 125; %perturbation amount, in mels
expt.shifts.mels{1} = [expt.shiftMag*expt.shiftDirs{2}, 0]; %amount of shift as [F1 F2]
expt.shifts.mels{2} = [expt.shiftMag*expt.shiftDirs{3}, 0]; %amount of shift as [F1 F2]

if bTestMode
    expt.nblocks = 1;
else
    expt.nblocks = 6;
end

% Pseudorandomize stimuli like this: In each 15-trial block, each word gets
% an equal number of trials (5): 1 is shifted up, 1 is shifted down, and
% 3 are unshifted. No perturbation trials are adjacent, even across blocks.
nTrialsPerPert = 1;
uniquePerts = 2; % shiftUp, shiftDown
nTrialsPerNonpert = 3;
expt.ntrials_per_block = nwords*(nTrialsPerPert*uniquePerts + nTrialsPerNonpert); %aka 15 trials per block.
expt.ntrials = expt.nblocks * expt.ntrials_per_block;
% Set expt.allWords, expt.listWords, expt.allConds, expt.listConds
expt = randomize_stimuli(expt,nTrialsPerPert,nTrialsPerNonpert); 

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

% This is where individual trial-level shift magnitude and direction gets set.
% shiftMag (singular) is a single value of positive 125.
% expt.listShiftDirs is a vector of 0, 1, and -1 for each trial,
% so shiftMags (plural) becomes a vector of values 0, 125, or -125
expt.shiftMags = expt.shiftMag*expt.listShiftDirs;

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
if expt.bTestMode
    runOrSkip = askNChoiceQuestion('Run duration practice?', {'run' 'skip'});
else
    runOrSkip = 'run'; % always run it outside of test mode
end

while strcmp(runOrSkip, 'run')
    exptDur.success = zeros(1,exptDur.ntrials);
    exptDur = run_modelComp_audapter(exptDur);
    rerun_response = askNChoiceQuestion(sprintf('Participant was successful on: %d/%d trials. Redo training?',sum(exptDur.success),length(exptDur.success)), {'redo' 'move on'});
    if strcmp(rerun_response,'move on')
        runOrSkip = 'skip';
    end
end

%% run compensation experiment
expt = run_modelComp_audapter(expt);
exptfile = fullfile(expt.dataPath,'expt.mat');
fprintf('Saved expt file: %s.\n',exptfile);


end %EOF
