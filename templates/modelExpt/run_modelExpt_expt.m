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

    %CONV Input arg defaults should be the settings for running the
    %experiment with real participants.
    
    %[The expt variable holds settings specific to this participant, as
    %well as settings used by modelExpt for all participants.
if nargin < 1, expt = []; end 
    %[When bTestMode is 1, we'll change various settings throughout the
    %experiment to make it faster to complete
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Experiment setup
expt.name = 'modelExpt';
if ~isfield(expt,'snum'), expt.snum = get_snum; end     %eg, sp247
expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
    %CONV Your expt file should be saved to:
    % 'C:\Users\Public\Documents\experiments\[expt.name]\acousticdata\[expt.snum]\'.
    % `get_acoustSavePath` will return that, given the input arguments.

% Load in existing expt.mat, if there is one
if isfile(fullfile(expt.dataPath, 'expt.mat'))
    bOverwrite = input('This participant already exists. Load in existing expt? (y/n): ', 's');
    if strcmp(bOverwrite,'y')
        load(fullfile(expt.dataPath, 'expt.mat'))
    end
end

% other expt.mat setup
if ~isfield(expt,'gender'), expt.gender = get_gender; end
expt.words = {'bed', 'dead', 'head'};


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
    if bTestMode
            %CONV: For text response options like the `input` command
            %below, you can put letters or numbers in parentheses to show
            %the person running your code what their response options are.
            %Also note in the next line how the code doesn't proceed until
            %an input of 1 or 2 is received.
        expt.groupnum = input('Which group? (1) normal or (2) perturbed? ');
        while ~any(expt.groupnum == [1 2])
            expt.groupnum = input('Invalid answer. Please enter 1 or 2: ');
        end
        expt.group = groups{expt.groupnum};
    else %if real participant, assign group randomly
        [expt.group, expt.groupnum] = get_sgroup(subjPath, groups);
    end
else
    check_sgroup(expt.group, groups);
    expt.groupnum = find(strcmp(expt.group, groups));
end
    % set new expt.dataPath based on group subfolder
expt.dataPath = fullfile(expt.dataPath, expt.group);

% timing
    %[[JITTER]]
expt.timing.stimdur = 2.5;          % time stim is on screen, in seconds
expt.timing.interstimdur = 1.25;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .75;  % maximum extra time between stims (jitter)


%% Stimuli setup

% set up [[CONDITIONS]] and number of trials
expt.conds = {'baseline' 'ramp' 'hold' 'washout'};

    %[ For the line below, we *could* just put `nwords = 3;`. But what if
    %we added another word to expt.words later? It might be hard to find
    %the bug in our code. Since nwords's value exists in relation to
    %expt.words, we should *define* nwords using that relationship.
nwords = length(expt.words);
if bTestMode
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
    %[ We want to end up with an array of words, one for each trial, such
    %that expt.listWords(n) is the stimulus word that should be presented
    %on the n'th trial.
    %
    % This is automatically done by set_exptDefaults if you do not define
    % the order yourself. In set_exptDefaults, the experiment is diveded
    % into "blocks" of words; each block has 1 instance of each stimulus
    % word. The order of the words is randomized within each block. This
    % makes sure the words are evenly distributed throughought the
    % experiment.
    %
    % You may need to change this default for your experiment though. To do
    % so, specify a word order here, before calling set_exptDefaults. You
    % need only to set the order of the indexes into the words
    % (expt.allWords), not the order of the actual words themselves
    % (expt.listWords). expt.listWords will be created automatically by
    % set_exptDefaults.
    %
    %[ Here's an example of setting expt.allWords. It
    % [[RANDOMIZES]] the order of words within each condition, aka "block".
    % This code is slightly complicated because our blocks aren't all the
    % same size. In the end though, each block displays each word an equal
    % number of times. You probably don't want to randomize words this way,
    % but it gives you an example of what this might look like.
rng('shuffle');
for blockIx = 1:length(expt.conds)
    ntrialsInBlock = length(find(expt.allConds == blockIx));
    wordIx = ceil(randperm(ntrialsInBlock) / (ntrialsInBlock/length(expt.words)));
    
    firstInBlock = find(expt.allConds == blockIx, 1, 'first');
    lastInBlock = find(expt.allConds == blockIx, 1, 'last');
    for itrial = firstInBlock:lastInBlock
        expt.allWords(itrial) = wordIx(1 + itrial-firstInBlock);
    end
end

%% Set other expt values
%There are a lot of other parameters you can set that control how the
%experiment looks or functions. If you don't set these here, default values
%will be set when you call set_exptDefaults in the next section . Here's
%all the categories of things that you can set:
    
        %{
        subject params:
            expt.snum:      participant ID
            expt.gender:    participant gender
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
                you are using in appears in  txt2ipa.m.
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
        trial indices: for example, a list of all trials with a certain 
            vowel. we wantthese to be set automatically. these are used
            primarily for data analysis
        %}

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
    
    %[ Some experiments will call their sister function multiple times. See
    %the very bottom of `run_varModOut_expt` for example, where it calls
    %`run_varMod_audapter` multiple times. That functionality isn't needed
    %for modelExpt, but I've written it so that if you *did* want to use
    %multiple sister function calls, you could. Note that you can run other
    %code in-between sister function calls if desired.
    

% run baseline
conds2run = {'baseline'};
expt = run_modelExpt_audapter(expt, conds2run);

% resave expt
save(exptfile, 'expt');
fprintf('Saved baseline data to expt file: %s.\n', exptfile);

% run ramp, hold, and washout
conds2run = {'ramp' 'hold' 'washout'};
expt = run_modelExpt_audapter(expt, conds2run);


end