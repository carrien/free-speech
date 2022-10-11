function [] = adjustOsts(expt, h_fig, word, trackingFileName)
% This function will be used by the button "Adjust OSTs" in the control window of an experiment display. The purpose of this
% is to adjust the OST files for a participant mid-experiment, if they have changed their speech such that the OSTs are no
% longer working (especially talking louder or something, where your thresholds may no longer be accurate)
% 
% INPUT ARGUMENTS: 
%       expt:           
%           expt structure from the experiment. For the sake of audpater_viewer this turns into exptOst (so it can be saved,
%           and then resaved over with the originals)
%       h_fig:
%           Figure handle from the experiment, so pause text can be appropriately included 
%       word:           
%           the word to look for in expt.inds.words. If empty or does not exist, just assumes that all trials should be used.
%           Use this when you are in an experiment that has multiple OST files, such as taimComp. If you have multiple words
%           that use one OST file (e.g., both "size" and "sigh" use some OST file called "sigh"), you can put in a cell array
%           {'size' 'sigh'} and the indices from expt.inds.words.size and expt.inds.words.sigh will be concatenated
%       trackingFileName:       
%           the name of the OST file, same use patterns as other trackingFileName arguments (i.e., 'size' would look for
%           sizeWorking in expt.trackingFileLoc). If this is empty, and word is also empty, just uses expt.trackingFileName.
%           If it is empty and word is NOT empty, uses the first word in word. 
%           *** NOTE: this is a separate argument because expt.trackingFileName may include multiple tracking file names for
%           experiments with multiple tracking files, such as taimComp. 
% 
% Note for usage in experiments proper: because the pause function for adjustOst is only checked at the beginning of a trial,
% one way to call adjustOsts on 'a' press is to use the word from the last trial, i.e. 
% 
%       adjustOsts(expt, h_fig, expt.listWords(trial_index - 1), expt.trackingFileName(expt.allWords(trial_index - 1))
% 
% For this usage, the experimenter would press 'a' during a trial that has the questionable word, and then right before the
% next trial started, adjustOsts would fire up. 
% 
% An alternative way to call this would be to use something like askNChoiceQuestion to determine what words to feed in, e.g. 
% 
%       word2adjust = askNChoicQuestion('What word would you like to adjust the OSTs for?', {'sigh' 'size' 'buyYogurt'}; 
%       adjustOsts(expt, h_fig, word2adjust, []); 
% 
% Where the empty argument for trackingFileName would look for an OST file named with word2adjust. Depending on your
% particular experiment structure you can tailor exactly how you want to call adjustOsts in your experiment engine. 
%           
%           
% 
% Process: 
% 1. Takes in expt and h_fig (so that you can run a split version of pause_trial) 
% 2. Compiles data from last 18 temp trials into one data file so it can be read by audapter_viewer all at once (if you don't
% have 18, it will just take the last however many you have) 
% --- If you are in an experiment that has multiple OST files (e.g. taimComp), "word" will be used to figure out which subset
% of trials can be used
% 3. Opens audapter_viewer with that data file and the expt 
% 4. Use audapter_viewer as normal 
% 5. Marks last temporary trial 1 for bChangedOsts
% 6. Saves a data file with those compiled trials (data_ostChange.mat)
% 7. Feeds new OST parameters into Audapter (so you don't have to do it in your own experiment) 
% 
% WARNING: DO NOT USE during the actual experimental phase of an experiment that simply turns on formant perturbation for an
% entire trial. This script indiscriminately feeds the OST file back into Audapter, which prevents trial-wide perturbation.
% 
% Accompanies function add_adjustOstButton to add a button to control screen to get to this script
% 
% Initiated RPK 6/2/2021
% Major change RPK 2022-01-03 to accommodate multiple OST files, for taimComp
% 
% 

dbstop if error 
%% Default arguments

if nargin < 3 || isempty(word), word = {}; end
% Change string inputs in word to cell 
if ischar(word)
    word = {word}; 
end
if nargin < 4 || isempty(trackingFileName)
    if nargin < 3 || isempty(word)
        if ~isfield(expt, 'trackingFileName')
            trackingFileName = 'measureFormants'; 
        else
            trackingFileName = expt.trackingFileName; 
        end
    elseif iscell(word)
        trackingFileName = word{1}; 
    end
end



% Set exptOst so that you don't lose original expt 
exptOst = expt; 
exptOst.trackingFileName = trackingFileName; 

%% Display faux pause information (without actually pausing) 
get_figinds_audapter;

% text params
pausetxt = 'The experiment has been paused. Please wait for a few moments.';
pausetxt = textwrap({pausetxt}, 50); 
conttxt = 'We will now continue with the experiment.';
txtparams.Color = 'white';
txtparams.FontSize = 60;
txtparams.HorizontalAlignment = 'center';
txtparams.Units = 'normalized';

% display pause text and wait for keypress
figure(h_fig(stim))
h1_sub = subplot(1,1,1);
set(h1_sub, 'color', 'black')
axis off
h_text = text(.5,.5,pausetxt,txtparams);
CloneFig(h_fig(stim),h_fig(dup))

%% Setup trials 

% Number of trials to compile
nCompiledTrials = 18; 

% OST file information 
if (~isfield(exptOst, 'trackingFileDir') && ~isfield(exptOst, 'trackingFileLoc')) 
    trackingFileDir = 'experiment_helpers'; 
elseif isfield(exptOst, 'trackingFileDir')
    trackingFileDir = exptOst.trackingFileDir; 
elseif isfield(exptOst, 'trackingFileLoc')
    trackingFileDir = exptOst.trackingFileLoc; 
end

ostPath = get_trackingFilePath(trackingFileDir, trackingFileName); 
% if strcmp(trackingFileDir, 'experiment_helpers')
%     ostPath = 'C:\Users\Public\Documents\software\free-speech\experiment_helpers\'; 
% else
%     ostPath = get_exptRunpath(trackingFileDir); 
% end

ostWorking = fullfile(ostPath, [trackingFileName 'Working.ost']); 
 

%% Get temporary data files

% Look for temporary trial directory
tempdirs = regexp(genpath(exptOst.dataPath),'[^;]*temp_trials','match')';
if isempty(tempdirs)
    % If there isn't one
    fprintf('No trials left to adjust OSTs for.\n')
    return;
elseif length(tempdirs) > 1
    fprintf('Too many temp directories. Aborting. \n')
    return;
end

tempdir = tempdirs{1}; 
trialnums = get_sortedTrials(tempdir);

% Get trials in the allowed subset (e.g., just ones in expt.inds.words.sigh)
allowedTrials = []; 
if isempty(word)
    % If you haven't specified word, then you can use all of the trials 
    allowedTrials = 1:expt.ntrials; 
else    
    % If you have specified word(s), then you can only use the trials that used that word(s) 
    % Note that this means you can take trials from, say, both sigh and size trials, but they should share an OST file
    for w = 1:length(word)
        allowedTrials = [allowedTrials exptOst.inds.words.(word{w})]; 
    end
end
trialnums = intersect(allowedTrials, trialnums); % Get the intersection of the subset of trials and the completed trials in temp

% Get last nCompiledTrials trials (finds the integers so that you get a full indexed list) 
trials2compile = find(round(trialnums) == trialnums, nCompiledTrials, 'last'); 
trials2compile = trialnums(trials2compile); % Just in case your trial list for some reason doesn't start at 1 ... like if you're only doing a subset

% Compile the data into a data.mat
compiledData = []; 
for t = 1:length(trials2compile)
    trialNo = trials2compile(t); 
    load(fullfile(tempdir, [num2str(trialNo) '.mat']), 'data'); 
    data.trial = trialNo; 
    compiledData = [compiledData; data]; 
end
    
% Set last trial's bChangeOst -> 1
load(fullfile(tempdir, [num2str(max(trials2compile)), '.mat']), 'data'); 
data.bChangeOst = 1; 
save(fullfile(tempdir, [num2str(max(trials2compile)), '.mat']), 'data'); 

% Clear data and save full compiled data as data_ostChange.mat
clear data; 
data = compiledData; 
save(fullfile(exptOst.dataPath, 'data_ostChange.mat'), 'data'); % Unclear if we actually need to save this

%% Open audapter viewer

% Using data (which is now compiledData)
audapter_viewer(data,exptOst); 
hGui = findobj('Tag','audapter_viewer'); 

% Pause the experiment
fprintf('Unpause the experiment when you have finished adjusting OST parameters.\n')
pause

% Backup in case you accidentally unpause it before you are done setting
try 
    waitfor(hGui); 
catch
end

% resume after keypress/audapter_viewer is gone
set(h_fig(stim),'CurrentCharacter','@')  % reset keypress
set(h_fig(ctrl),'CurrentCharacter','@')
set(h_fig(dup),'CurrentCharacter','@')

% Send in new values to audapter before resetting text
Audapter('ost', ostWorking, 0);
fprintf('New OST values fed into Audapter.\n')

% Resave expt
save(fullfile(expt.dataPath, 'expt.mat'), 'expt'); % Because in some cases you may have changed expt to have a different trackingFileName 
fprintf('Original expt structure saved.\n'); 

% Refresh text
delete_exptText(h_fig, h_text)
pause(0.25)
h_text(1) = draw_exptText(h_fig, 0.5, 0.5, conttxt, txtparams); % display continue text
pause(2)
delete_exptText(h_fig, h_text)      % clear continue text
pause(1)



end