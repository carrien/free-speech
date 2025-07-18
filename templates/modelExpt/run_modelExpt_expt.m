function expt = run_modelExpt_expt(expt, bTestMode)
% RUN_MODELEXPT_EXPT    Serves as a model for what experiments in
% SMNG can/should look like. See companion RUN_MODELEXPT_AUDAPTER.
%   RUN_MODELEXPT_EXPT(expt, bTestMode)
%
% [[HEADERS]] The structure of this experiment is that a participant will
% read words from the list expt.words and say them out loud. We record
% their voice in Audapter. This experiment should be run on all
% participants twice: on each run-through the participant will either be
% assigned to the 'normal' or 'perturbed' group. Since this is a model
% experiment, both groups actually function identically.


%{ 
-------------------------------
          USER'S GUIDE
-------------------------------

Hi. This experiment was designed to help members of SMNG lab interpret the 
code for existing experiments, and serve as a template for making new
experiments. There are a couple things you should know before you start:

1.) SPECIAL COMMENTS
    There are multiple types of comments used in this document.
    a.) NORMAL COMMENTS -- Preceded by % -- These could appear as-is in a
        real experiment's code base. Generally very short.
    b.) EXPLANATORY COMMENTS -- Preceded by %[ -- These give more detail to
        help you understand why the code was written the way it is, or to
        explain a concept briefly.
    c.) CONVENTION COMMENTS -- Preceded by %CONV -- This is less about "how
        the code works," and more like "our lab typically does it this way."

2.) LINKS TO REFERENCE GUIDE
    Words in [[DOUBLE BRACKETS]] point to the reference guide, which can be
    found at this website:
    https://github.com/carrien/free-speech/blob/master/templates/modelExpt/README.md

    Information or a concept which takes a while to explain goes there.

THIS EXPERIMENT ACTUALLY WORKS. Try using breakpoints and following
variables through their lifecycle to see how they're used. Double clicking
a variable highlights other places it's used. Ctrl+F works too.

YOU CAN COPY AND PASTE various chunks of this code into your experiment.
Try to generally understand what it's doing, though...

IF YOU WANT TO FIDDLE AROUND with this code, by all means do so! See
[[EDITING]] in the reference guide for instructions.

REMEMBER that you can use the commands `help` and `doc` on functions you 
don't recognize or understand. For any built-in Matlab functions,
the documentation is generally quite good. [[DEBUGGING]] with breakpoints
is good too.

%}


%% Handle input arguments

    %CONV The default value of input arguments should assume that you're
    % running a real participant. When piloting/testing, you can always
    % override them.
    
    %[The expt variable holds metadata about modelExpt (how many trials
    % to run), AND information specific to our participant (LPC Order).
if nargin < 1, expt = []; end 
    %[When bTestMode is 1, we'll change various settings throughout the
    %experiment to make it faster to complete
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Experiment setup
expt.name = 'modelExpt';
expt.bTestMode = bTestMode;
if ~isfield(expt,'snum'), expt.snum = get_snum; end     %eg, sp247
expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
    %CONV Your expt file should be saved to:
    % 'C:\Users\Public\Documents\experiments\[expt.name]\acousticdata\[expt.snum]\'.
    % `get_acoustSavePath` will return that, given the input arguments.

% Load in existing expt.mat, if there is one
if isfile(fullfile(expt.dataPath, 'expt.mat'))
    bOverwrite = input('This participant already exists. Load in existing expt? (y/n): ', 's');
    if strcmp(bOverwrite,'y')
        load(fullfile(expt.dataPath, 'expt.mat'), 'expt')
    end
end

% other expt.mat setup
if ~isfield(expt,'gender'), expt.gender = get_height; end

% counterbalancing word lists

    % [[COUNTERBALANCING]]
    
    %[ This block starts by checking if the participant has already been
    %assigned to a group. We check this by seeing if their expt file
    %already contains the field 'group'. If in a previous run-through of
    % the experiment the participant was in one group, now they'll be in
    % the other group. Many experiments, where participants only perform
    % one session, will not need this section of code.
    % 
groups = {'normal', 'perturbed'};
if ~isfield(expt,'group')
    if expt.bTestMode
            %CONV: For text response options like the `input` command
            %below, you can put letters or numbers in parentheses to show
            %the person running your code what their response options are.
            % `askNChoiceQuestion` doesn't let you move on until you give
            % an approved response -- in this case, "1" or "2".
        expt.groupnum = askNChoiceQuestion('Which group? (1) Normal or (2) perturbed?', [1 2]);
        expt.group = groups{expt.groupnum};
    else %if real participant, assign group randomly
        [expt.group, expt.groupnum] = get_sgroup(expt.dataPath, groups);
    end
else
    check_sgroup(expt.group, groups);
    expt.groupnum = find(strcmp(expt.group, groups));
end
    % set new expt.dataPath based on group subfolder
expt.dataPath = fullfile(expt.dataPath, expt.group);

% timing
    %[[JITTER]]
expt.timing.stimdur = 1.8;          % time stim is on screen, in seconds
expt.timing.interstimdur = 0.75;    % minimum time between stims, in seconds
expt.timing.interstimjitter = 0.75; % maximum extra time between stims (jitter)


%% Stimuli setup

expt.words = {'bed', 'dead', 'head'};
% set up [[CONDITIONS]] and number of trials
expt.conds = {'baseline' 'ramp' 'hold' 'washout'};

    %[ For the line below, we *could* just put `nwords = 3;`. But what if
    %we added another word to expt.words later? It might be hard to find
    %the bug in our code. Since nwords's value exists in relation to
    %expt.words, we should *define* nwords using that relationship.
nwords = length(expt.words);
if expt.bTestMode
    testModeReps = 1;
    nBaseline =           testModeReps * nwords;
    nRamp =               testModeReps * nwords;
    nHold =               testModeReps * nwords * 2;
    nWashout =            testModeReps * nwords;
    expt.breakFrequency = testModeReps * nwords;
else
    nBaseline =     4 * nwords;
    nRamp =         4 * nwords;
    nHold =         8 * nwords;
    nWashout =      4 * nwords;
    expt.breakFrequency = 4 * nwords;
end

expt.ntrials = nBaseline + nRamp + nHold + nWashout;
    %[ Gives us an array of trial #'s after which we'll have a break
expt.breakTrials = expt.breakFrequency:expt.breakFrequency:expt.ntrials;

    %[ Gives us an array of numbers, one for each trial. The value of the
    %number is the condition of that trial. So if expt.allConds(40) == 3,
    %it tells us that the 40th trial is during the Hold condition.
expt.allConds = [1*ones(1,nBaseline) 2*ones(1,nRamp) 3*ones(1,nHold) 4*ones(1,nWashout)];


% set word order
    %[ We want to make a vector of words X units long, where X is the
    %number of trials in our experiment, and the Yth element is the
    %stimulus word on trial Y. This vector is called expt.listWords. It
    %looks something like {'bed', 'head', 'dead', 'head', 'bed', ...}
    %
    % We also want to make another vector X units long, but instead of
    % containing the actual word, it contains an index to the word. It
    % looks something like [1, 3, 2, 3, 1 ...]. This is expt.allWords. The
    % value in expt.allWords is an index into expt.words. So since the
    % second element of expt.allWords is 3, that corresponds to
    % expt.words{3}, ie, 'head'
    %
    % More info about the words, allWords, listWords convention is on our
    % website -- https://kb.wisc.edu/smng/117641
    
    %[ randomize_wordOrder, well, [[RANDOMIZES]] the word order. It also 
    % ensures that the same word isn't presented on consecutive trials.
rng('shuffle');
expt.allWords = randomize_wordOrder(nwords, expt.ntrials / nwords);
expt.listWords = expt.words(expt.allWords);

%% Perturbation setup

%[ In this experiment, we use Audapter's method for perturbing formants
%which sets the directionality and proportion of F1 vs F2 shifts with a phi
%value (shiftAngles), and the amount of shift with an amplitude value
%(shiftMags). By setting the shiftMag to 0 in the 'normal' group, there's
%no shift.

% set max shift amount based on group
switch expt.group
    case 'normal'
        expt.shiftMag = 0;
    case 'perturbed'
        expt.shiftMag = 125;
end

% assign shift amount for each phase
expt.shiftMags = [zeros(1,nBaseline), ...        % baseline
    sort(linspace(0, expt.shiftMag, nRamp)), ... % ramp
    ones(1, nHold) .* expt.shiftMag, ...         % hold
    zeros(1, nWashout)];                         % washout

%[ A phi value of zero means F1 up, F2 unchanged. See Audapter manual.
expt.shiftAngles = zeros(1,nBaseline+nRamp+nHold+nWashout);

%% Set other expt values
%There are a lot of other parameters you can set that control how the
%experiment looks or functions. If you don't set these here, default values
%will be set when you call set_exptDefaults in the next section . Here's
%all the categories of things that you can set:
    
        %{
        subject params:
            expt.snum:      participant ID
            expt.gender:    participant gender. Sets default Audapter LPC
            expt.dataPath:  path on local machine where data is stored
        environment params (we want these to be set automatically):
            expt.date: date the experiment was run
            expt.compName: the computer the experiment was run on
            expt.username: the person logged in to the computer; the person
                who ran the experiment
        experiment params:
            expt.conds: conditions use in the experiment (e.g., baseline, 
                hold washout). you should definitely set these by hand.
            expt.allConds: index of conditions (expt.conds) for each trial
            expt.listConds: the name (string) of conditions for each trial
            expt.words: stimuli words used in the experiment
            expt.allWords: index of stimuli (expt.words) for each trial
            expt.listWords: the word (string) of the stimulus for each
                trial
            expt.vowels: list of the vowel for each stimulus word (the
                order should match!). can be set automatically if the word
                you are using appears in txt2arpabet.m.
            expt.allVowels: index of vowels (expt.vowels) for each trial
            expt.listVowels: the vowel (string) of the stimulus for each
                trial
            expt.colors: the colors for the stimuli (as a vector of strings)
            expt.allColors: index of stimulus color (expt.colors) for each 
                trial
            expt.listColor: stimulus color (string) for each trial
            expt.colorvals: the color for the stimuli (as a matlab RGB
                vector)
            expt.nblocks: number of blocks in the experiment
            expt.ntrials_per_block: number of trials in each block
            expt.ntrials: total number of trials in the experiment
            expt.breakFrequency: the number of trials between breaks
            expt.breakTrials: the trials after which there will be a break
            expt.stimulusText: What actually displays to participants in a
                trial
            expt.allStimulusText: Indexes of stimulusText for each trial
            expt.listStimulusText: The stimulusText string for each trial
        formant shifting params (for Audapter):
            expt.shiftMags: vector of the magnitude of formant shifts for 
                each trial
            expt.shiftAngles: vector of the angle in F1/F2 space of shifts 
                for each trial
        timing:
            expt.timing.stimdur: the duration the stimulus is visible on each
                trial
            expt.timing.interstimdur: the break between each trial
            expt.timing.jitter: added jitter between each trial to make the
                experiment less rhythmic
            expt.timing.visualfbdur: how long any visual feedback (like about
                vowel duration) is displayed.
        duration tracking:
            expt.durcalc.min_dur = .25: minimum acceptable duration
            expt.durcalc.max_dur = .5: maximum acceptable duration
            expt.durcalc.ons_thresh = 0.3: amplitude threshold for vowel
                onset detection
            expt.durcalc.offs_thresh = 0.4: amplitude threshold for vowel
                offset detection
        amplitude tracking -- 
            amplcalc.min_ampl = 0.04: minimum acceptable amplitude
            amplcalc.max_ampl = 0.24: maximum acceptable amplitude
            amplcalc.ons_thresh = 0.01:
            amplcalc.offs_thresh = 0.015;
        instructions:
            expt.instruct: text string of instructions at start of
                experiment
        binaries:
            expt.bUseTrigs: use triggers (for MRI experiments)
            expt.bManualMode: manual mode (requires keypress to advance trials)
        restart params for keeping track of crashes-- startTrial, isRestart, crashTrials
        trial indices:
            expt.inds. (...)
            For example, expt.inds.words lists all trials with a certain 
            word, and expt.inds.conds lists all trials for a given
            condition. This is set automatically for any fields
            in expt which use the format X, allX, listX.
        %}

%% Run pre-experiment phase to set LPC order
%[ For most experiments, we run a pre-experiment phase with a few vowels
% to set a good LPC Order in Audapter for the participant. The function
% run_checkLPC handles most of this, then sets the LPC value in
% expt.audapterParams. You can configure exptPre to change the pretest 
% phase, for example, changing the stimulus words or number of trials.
if ~expt.bTestMode
    bRunLPCcheck = 1;
else
    bRunLPCcheck = askNChoiceQuestion('[Test mode only] Run LPC check pretest phase (1), or skip it (0)? ', [1 0]);
end
if bRunLPCcheck
    exptPre.words = {'bid' 'bat' 'bed'};
    if expt.bTestMode
        exptPre.ntrials = length(exptPre.words) * 2;
    else
        exptPre.ntrials = length(exptPre.words) * 10;
    end
    [expt, ~] = run_checkLPC(expt, exptPre);

    %[ This line is a cue to the person running the experiment to refer to
    %written instructions (normally in the KB) before continuing the code.
    input('Read instructions, then press ENTER to go to main phase', 's');
end

%% save experiment file
    %[Makes a folder if one's not there already.
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end
exptfile = fullfile(expt.dataPath,'expt.mat');

    %[ Once you've done all the expt file configuration *you* need, run
    %this to set other fields to default values. This helps us standardize
    %fields across experiments. `set_exptDefaults` sets A LOT of fields. If
    %for your experiment, you think you need to save a new type of
    %information in expt.mat, first check if we have a name for that type
    %of data already. 
    
expt = set_exptDefaults(expt);

    %[ `savecheck` will ask if you want to overwrite an existing file
    %before doing so. If you click Cancel on that "overwrite?" popup,
    %bSave will be false and the file won't be saved.

    %CONV Boolean variables, which have a value of true or false, start
    %with b. For example, bSave and bTestMode.
bSave = savecheck(exptfile);
if bSave
    save(exptfile, 'expt')
    fprintf('Saved expt file: %s.\n',exptfile);
end

%% goto sister function (run_xx_audapter)

    % [[SISTER FUNCTIONS]]
    
    %[ Some experiments run a few conditions of the experiment, do
    %something else (like wait for 10 minutes), then run the remaining
    %conditions of the experiment. The below code shows how to do that.
    %  If you just want to run all conditions back to back, just
    %set conds2run to all conditions, then only call run_xx_audapter once.
    

% run baseline
conds2run = {'baseline'};
expt = run_modelExpt_audapter(expt, conds2run);

% resave expt
save(exptfile, 'expt');
fprintf('Saved baseline data to expt file: %s.\n', exptfile);

% run ramp, hold, and washout
conds2run = {'ramp' 'hold' 'washout'};
expt = run_modelExpt_audapter(expt, conds2run);


end %EOF
