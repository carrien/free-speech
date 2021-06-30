function [] = adjustOsts(expt, h_fig)
% This function will be used by the button "Adjust OSTs" in the control window of an experiment display. The purpose of this
% is to adjust the OST files for a participant mid-experiment, if they have changed their speech such that the OSTs are no
% longer working (especially talking louder or something, where your thresholds may no longer be accurate)
% 
% Process: 
% 1. Takes in expt and h_fig (so that you can run a split version of pause_trial) 
% 2. Compiles data from last 18 temp trials into one data file so it can be read by audapter_viewer all at once (if you don't
% have 18, it will just take the last however many you have) 
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
% 
% 

dbstop if error 

%% Display faux pause information (without actually pausing) 
get_figinds_audapter;

% text params
pausetxt = 'The experiment has been paused. Please wait for a few moments.';
pausetxt = textwrap({pausetxt}, 50); 
conttxt = 'We will now continue with the experiment.';
txtparams.Color = 'white';
txtparams.FontSize = 60;
txtparams.HorizontalAlignment = 'center';

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
if (~isfield(expt, 'trackingFileDir') && ~isfield(expt, 'trackingFileLoc')) 
    trackingFileDir = 'experiment_helpers'; 
elseif isfield(expt, 'trackingFileDir')
    trackingFileDir = expt.trackingFileDir; 
elseif isfield(expt, 'trackingFileLoc')
    trackingFileDir = expt.trackingFileLoc; 
end

if strcmp(trackingFileDir, 'experiment_helpers')
    ostPath = 'C:\Users\Public\Documents\software\free-speech\experiment_helpers\'; 
else
    ostPath = get_exptRunpath(trackingFileDir); 
end

if ~isfield(expt, 'trackingFileName')
    trackingFileName = 'measureFormants'; 
else
    trackingFileName = expt.trackingFileName; 
end

ostWorking = fullfile(ostPath, [trackingFileName 'Working.ost']); 
 

%% Get temporary data files

% Look for temporary trial directory
tempdirs = regexp(genpath(expt.dataPath),'[^;]*temp_trials','match')';
if isempty(tempdirs)
    % If there isn't one
    fprintf('No trials left to adjust OSTs for.\n')
    expPath = [];
    return;
elseif length(tempdirs) > 1
    fprintf('Too many temp directories. Aborting. \n')
    return;
end

compiledData = []; 

tempdir = tempdirs{1}; 
trialnums = get_sortedTrials(tempdir);

% Get last nCompiledTrials trials (finds the integers so that you get a full indexed list) 
trials2compile = find(round(trialnums) == trialnums, nCompiledTrials, 'last'); 
trials2compile = trialnums(trials2compile); % Just in case your trial list for some reason doesn't start at 1 

for t = 1:length(trials2compile)
    trialNo = trials2compile(t); 
    load(fullfile(tempdir, [num2str(trialNo) '.mat'])); 
    compiledData = [compiledData; data]; 
end
    
% Set last trial's bChangeOst -> 1
load(fullfile(tempdir, [num2str(max(trials2compile)), '.mat'])); 
data.bChangeOst = 1; 
save(fullfile(tempdir, [num2str(max(trials2compile)), '.mat']), 'data'); 

% Clear data and save full compiled data as data_ostChange.mat
clear data; 
data = compiledData; 
save(fullfile(expt.dataPath, 'data_ostChange.mat'), 'data'); % Unclear if we actually need to save this

%% Open audapter viewer

% Using data (which is now compiledData)
audapter_viewer(data,expt); 
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

% Refresh text
delete(h_text)
h_text = text(.5,.5,conttxt,txtparams); % display continue text
CloneFig(h_fig(stim),h_fig(dup))
pause(1)
delete(h_text)                          % clear continue text
CloneFig(h_fig(stim),h_fig(dup))
pause(1)



end