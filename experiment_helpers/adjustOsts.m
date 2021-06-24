function [] = adjustOsts(expt, h_fig)
% This function will be used by the button "Adjust OSTs" in the control window of an experiment display. The purpose of this
% is to adjust the OST files for a participant mid-experiment, if they have changed their speech such that the OSTs are no
% longer working (especially talking louder or something, where your thresholds may no longer be accurate)
% 
% Process: 
% 1. Takes in expt and h_fig (so that you can run the normal pause_trial script) 
% 2. Compiles data from last 9 (-18?) temp trials into one data file so it can be read by audapter_viewer all at once 
% 3. Opens audapter_viewer with that data file and the expt 
% 4. Use audapter_viewer as normal 
% 5. Marks last temporary trial 1 for bChangedOsts
% 
% Initiated RPK 6/2/2021
% 
% 

dbstop if error 

% Number of trials to compile
nCompiledTrials = 18; 

% OST file information 
if (~isfield(expt, 'trackingFileDir') && ~isfield(expt, 'trackingFileLoc')) 
    ostPath = 'C:\Users\Public\Documents\software\free-speech\experiment_helpers'; 
elseif isfield(expt, 'trackingFileDir')
    ostPath = get_exptRunpath(expt.trackingFileDir); 
elseif isfield(expt, 'trackingFileLoc')
    ostPath = get_exptRunpath(expt.trackingFileLoc); 
end

if ~isfield(expt, 'trackingFileName')
    trackingFileName = 'measureFormants'; 
else
    trackingFileName = expt.trackingFileName; 
end

ostWorking = fullfile(get_exptRunpath(expt.name), [trackingFileName 'Working.ost']); 
 

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
save(fullfile(tempdir, [num2str(max(trials2compile)), '.mat'])); 

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
pause_trial(h_fig); 

% Backup in case you accidentally unpause it before you are done setting
try 
    waitfor(hGui); 
catch
end


%% Feed in new OST value to Audapter
Audapter('ost', ostWorking, 0);
fprintf('New OST values fed into Audapter.\n')


end