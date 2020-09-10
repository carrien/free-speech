function expt = cwn_run_modelExpt_expt(expt, bTestMode)
% RUN_MODELEXPT_EXPT    Serves as a model for what experiments in
% SMNG can/should look like. See companion RUN_MODELEXPT_AUDAPTER.
%   RUN_MODELEXPT_EXPT(expt, bTestMode)




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
    Words in [[DOUBLE BRACKETS]] point to the reference guide. Go to
    modelExpt_reference.m. Information or a concept which takes a while to
    explain goes there.

THIS EXPERIMENT ACTUALLY WORKS. Try using breakpoints and following
variables through their lifecycle if you're confused about what they do.

YOU CAN COPY AND PASTE various chunks of this code into your experiment.
Try to generally understand what it's doing, though...

IF YOU WANT TO FIDDLE AROUND with this code, by all means do so! Simply
copy all the code into a new script, then save it *locally* on your
computer. (Please 

REMEMBER that you can use the commands `help` and `doc` on functions you 
don't recognize or understand. For any built-in Matlab functions,
the documentation is generally quite good.
%}


%% Handle input arguments

%CONV Input arg defaults should be the settings for running the experiment with real participants
    %[The expt variable holds settings specific to this participant, as well
    %[as settings used by modelExpt for all participants.
if nargin < 1, expt = []; end 
%[ If bTestMode == 1, change various settings to make the experiment faster to complete
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Experiment setup
expt.name = 'modelExpt';
if ~isfield(expt,'snum'), expt.snum = get_snum; end     %eg, sp247
expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
    %CONV Your expt file should be saved to:
    % 'C:\Users\Public\Documents\experiments\[expt.name]\acousticdata\[expt.snum]\'.
    % `get_acoustSavePath` will return that, given the input arguments.

% Load in existing expt.mat
% TODO description
if isfile(fullfile(expt.dataPath, 'expt.mat'))
    bOverwrite = input('This participant already exists. Load in existing expt? (y/n): ', 's');
    if strcmp(bOverwrite,'y')
        load(fullfile(expt.dataPath, 'expt.mat'))
    end
end

% other expt.mat setup
% TODO description here?
if ~isfield(expt,'gender'), expt.gender = get_gender; end



% counterbalancing word lists
    % [[COUNTERBALANCING]]
% TODO add more descriptions here
if ~isfield(expt, 'population')
    % Get pt population
    if ~isempty(strfind(expt.snum, 'pilot')) || ~isempty(strfind(expt.snum,'test')) || bTestMode
        pop = 'test'; % e.g. pilot_001
    else
        pop = 'control'; % control will be sp001
    end
    
    % Get server location for permutation files
    permsPath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\modelExpt';
    localPermsPath = fullfile(get_gitPath, 'current-studies', 'modelExpt');
    
    if bTestMode % in test mode, you choose word order
            %CONV: For text response options like the `input` command
            %below, you can put letters or numbers in parentheses to show
            %the person running your code what their response options are.
            %In this case, they're prompted to respond with b or h.
        permIx_input = input('Which word list? (h)ead/bed/dead or (b)id/bed/bad: ', 's');
        if permIx_input == 'b'
            permIx = 2;
        else
            permIx = 1;
        end
        [~, expt.words] = get_cbPermutation(expt.name, localPermsPath, pop, permIx);
    else % in real experiment, word order comes from permutation file
        if exist(permsPath, 'dir')
            % get the words and their index
            [permIx, expt.words] = get_cbPermutation(expt.name, permsPath, pop);
            set_cbPermutation(expt.name, permIx, permsPath, pop); % increment by one
        else % if can't access server
            permIx = floor(mod(cputime, 2)) + 1; % "randomly" either 1 or 2
            [~, expt.words] = get_cbPermutation(expt.name, localPermsPath, pop, permIx);
            set_cbPermutation(expt.name, permIx, localPermsPath, pop); % increment by one
            warning('Server did not respond. Using random word list. Experiment will still run.')
        end
    end

    % expt.words is either {'head' 'bed' 'dead'} or {'bid' 'bed' 'bad'}
    expt.permIx = permIx; 
end

% stimuli
expt.conds = {'baseline' 'ramp' 'hold' 'washout'};

    %[By modularizing the number of words into nwords, we can guarantee all
    %[our conditions will include each word the same number of times, even
    %[if later we decide to change the number of words in expt.words
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

%% Stimuli setup

% timing
    %[[JITTER]]
expt.timing.stimdur = 2.5;          % time stim is on screen, in seconds
expt.timing.interstimdur = 1.25;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .75;  % maximum extra time between stims (jitter)

% stimuli themselves
expt.ntrials = nBaseline + nRamp + nHold + nWashout;
    %[ Gives us an array of trial #'s after which we'll have a break
expt.breakTrials = expt.breakFrequency:expt.breakFrequency:expt.ntrials;

    %[ Gives us an array of numbers, one for each trial. The value of the
    %number is the condition of that trial. So if expt.allConds(40) == 3,
    %it tells us that the 40th trial is during the Hold condition.
expt.allConds = [1*ones(1,nBaseline) 2*ones(1,nRamp) 3*ones(1,nHold) 4*ones(1,nWashout)];


% set word order
    %[ Gives us an array of words, one for each trial. stimList(n) gives
    % us the word that will be the stimulus word on the n'th trial.
    
    %[ This loop puts the words to be in the same order, over and over
    %again, by using modulo (`mod`). bid bed bad, bid bed bad, etc.
    
    % TODO show example of random word order w/ no matching edges
for i = 1:expt.ntrials
    expt.stimList{i} = expt.words{1 + mod(i-1, nwords)};
end
        

%% save experiment file
    %[Makes a folder if one's not there already. `savecheck` will ask if you
    %[want to overwrite an existing file before doing so. If you click
    %[Cancel on that "overwrite?" popup, bSave will be false and the file
    %[won't be saved.
    
    %CONV Boolean variables, which have a value of true or false, start
    %with b. For example, bSave and bTestMode.
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end
exptfile = fullfile(expt.dataPath,'expt.mat');
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