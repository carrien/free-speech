function [expt] = set_exptDefaults(expt)
%SET_EXPTDEFAULTS  Set missing experiment parameters to defaults.
%   SET_EXPTDEFAULTS(EXPT) replaces missing fields in EXPT with default
%   values for those fields.

if nargin < 1 || isempty(expt), expt = struct; end

fprintf('Setting defaults...\n\n');
expt = set_missingField(expt,'name','default');

%% subject parameters
if ~isfield(expt,'snum')     % prompt for snum if not defined
    expt.snum = get_snum;
else                         % otherwise validate snum
    expt.snum = get_snum(expt.snum);
end
if ~isfield(expt,'gender')   % prompt for gender if not defined
    expt.gender = get_height;
else                         % otherwise validate gender
    expt.gender = get_gender(expt.gender);
end
if ~isfield(expt,'dataPath') % prompt for dataPath if not defined
    expt.dataPath = get_dataPath;
end

%% environment parameters
expt = set_missingField(expt,'date',datetime);    %sets date to current date if not defined
expt = set_missingField(expt,'time',datestr(now,'HH:MM:SS')); %set time to current time
expt = set_missingField(expt,'compName',getenv('COMPUTERNAME'));  %gets name of computer
expt = set_missingField(expt,'username',getenv('username'));  %gets current username (whoever is logged in while running experiment)
    
%% experiment parameters
% conditions
expt = set_missingField(expt,'conds',{'test'});

% words
expt = set_missingField(expt,'words',{'bed'});

% vowels
expt = set_missingField(expt,'bIgnoreVowels',0);
if expt.bIgnoreVowels
    expt.vowels = {'null'};
elseif ~isfield(expt,'vowels')
    [vowels,~,ivowels] = unique(txt2arpabet(expt.words));
    if length(vowels) == length(ivowels), vowels = vowels(ivowels); end
    expt = set_missingField(expt,'vowels',vowels);
end

% colors
expt = set_missingField(expt,'colors',{'white'});
expt = set_missingField(expt,'colorvals',{[1 1 1]});

% trials, blocks, and breaks
expt = set_missingField(expt,'nblocks',1);
expt = set_missingField(expt,'ntrials_per_block',10);
expt = set_missingField(expt,'ntrials',expt.nblocks*expt.ntrials_per_block);
expt = set_missingField(expt,'breakFrequency',20);
expt = set_missingField(expt,'breakTrials',expt.breakFrequency:expt.breakFrequency:expt.ntrials-1);

% stimulus order (indices)
expt = set_missingField(expt,'allConds',randi(length(expt.conds),[1,expt.ntrials]));
nwords = length(expt.words);
for i = 1:ceil(expt.ntrials/nwords)
    indStart = (i-1)*nwords+1;
    indEnd = min(i*nwords,expt.ntrials);
    rp = randperm(nwords);
    allWords(indStart:indEnd) = rp(1:length(indStart:indEnd));
end
expt = set_missingField(expt,'allWords',allWords);
expt = set_missingField(expt,'allVowels',zeros(size(expt.ntrials)),0); % placeholder; not printed
expt = set_missingField(expt,'allColors',randi(length(expt.colors),[1,expt.ntrials]));

% stimulus order (names)
expt = set_missingField(expt,'listConds',expt.conds(expt.allConds));
expt = set_missingField(expt,'listWords',expt.words(expt.allWords));
if ~isempty(expt.vowels)
    if expt.bIgnoreVowels
        expt.listVowels = repmat(expt.vowels, [1 expt.ntrials]);
    else
        expt = set_missingField(expt,'listVowels',txt2arpabet(expt.listWords));
    end
    if any(expt.allVowels == 0)
        for t=1:expt.ntrials
            expt.allVowels(t) = find(strcmp(expt.listVowels{t},expt.vowels));
        end
    end
end
expt = set_missingField(expt,'listColors',expt.colors(expt.allColors));

% formant alteration parameters (for Audapter studies)
expt = set_missingField(expt,'shiftMags',zeros(1,expt.ntrials));
expt = set_missingField(expt,'shiftAngles',zeros(1,expt.ntrials));

% actual stimulus string shown to participant
expt = set_missingField(expt,'stimulusText',expt.words);
expt = set_missingField(expt,'allStimulusText',expt.allWords);
if all(strcmp(expt.words, expt.stimulusText)) 
    expt = set_missingField(expt,'listStimulusText',expt.listWords);
else  %, make list from stimulusText instead of words
    expt = set_missingField(expt,'listStimulusText',expt.stimulusText(expt.allStimulusText));
end

%% stimulus timing parameters, in seconds
timing.stimdur = 1.5;            % time of recording
timing.visualfbdur = 0.5;      % time visual feedback is shown
timing.interstimdur = 0.5;     % minimum time between stims
timing.interstimjitter = 0.5;  % maximum extra time between stims (jitter)
expt = set_missingField(expt,'timing',timing);

%% duration tracking parameters
durcalc.min_dur = .35;         %
durcalc.max_dur = .6;
durcalc.ons_thresh = 0.15;
durcalc.offs_thresh = 0.5;
durcalc.bFirst_offs_thresh = 1;
durcalc.bPrintDuration = 0;
durcalc.bMeasureOst = 0;
expt = set_missingField(expt,'durcalc',durcalc);

%% amplitude tracking parameters
amplcalc.min_ampl = 0.04; %0.02;
amplcalc.max_ampl = 0.24; %0.2;
amplcalc.ons_thresh = 0.01;
amplcalc.offs_thresh = 0.015;
expt = set_missingField(expt,'amplcalc',amplcalc);

%% instructions
instruct = get_defaultInstructions;
expt = set_missingField(expt,'instruct',instruct);

%% binary variables
expt = set_missingField(expt,'bUseTrigs',0);   % triggers
expt = set_missingField(expt,'bManualMode',0); % manual mode (requires keypress to advance trials)

%% restart parameters
expt = set_missingField(expt,'startTrial',1);
expt = set_missingField(expt,'startBlock',ceil(expt.startTrial/expt.ntrials_per_block));
expt = set_missingField(expt,'isRestart',0);
expt = set_missingField(expt,'crashTrials',[]);

%% trial indices
expt.inds = get_exptInds(expt,{'conds', 'words', 'vowels', 'colors'});

fprintf('Done setting defaults.\n');

end

function [dataPath] = get_dataPath()

bCurrDir = input(sprintf('Save data to current directory (%s)? [y/n] ',cd), 's');
    while ~any(strcmp(bCurrDir,{'y','n'}))
        bCurrDir = input('Please enter y/n: ','s');
    end
    if strcmp(bCurrDir, 'y')
        dataPath = cd;
    elseif strcmp(bCurrDir, 'n')
        dataPath = uigetdir(get_exptSavePath,'Select data directory');
    end

end
