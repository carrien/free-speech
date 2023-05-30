function [expt, exptPre] = run_checkLPC(expt, exptPre)
% Runs a short speech experiment using run_measureFormants_audapter, then
% plots formant means using check_audapterLPC. Useful for determining LPC
% order and vowel means for participants in most speech experiments. The
% indended use is that this will happen near the beginning of a study,
% before the main phase. 
% 
% The result of this function is saving a file `exptPre`. The variable 
% exptPre can also be passed back as an output argument.
%
% This function assumes the input argument `expt` has the following fields:
%   expt.dataPath
%   expt.snum
%   expt.gender

% 2022-11 Chris Naber init.

%% setup
if nargin < 2
    exptPre = [];
end

defaultParams.snum = expt.snum;
defaultParams.gender = expt.gender;
defaultParams.dataPath = fullfile(expt.dataPath, 'pre');
defaultParams.words = {'bid' 'bat' 'bed'};
defaultParams.conds = {'noShift'};
defaultParams.trackingFileLoc = 'experiment_helpers'; % default single-syllable, one word Audapter OST file
defaultParams.trackingFileName = 'measureFormants';   % default single-syllable, one word Audapter OST file
defaultParams.audapterParams.fb = 3;                  % feedback mode. 3=participant hears speech and noise
if isfield(expt, 'bTestMode') && expt.bTestMode
    defaultParams.nblocks = 2;  % number of repetitions of each word
else
    defaultParams.nblocks = 10; % number of repetitions of each word
end

% reconcile exptPre and defaultParams
exptPre = set_missingFields(exptPre, defaultParams, 0);

% settings that require reconciled exptPre and defaultParams
exptPre.ntrials = exptPre.nblocks * length(exptPre.words);
if ~isfield(exptPre, 'breakTrials')
    exptPre.breakTrials = exptPre.ntrials; % no breaks
end
refreshWorkingCopy(exptPre.trackingFileLoc,exptPre.trackingFileName,'both');
if ~exist(exptPre.dataPath, 'dir')
    mkdir(exptPre.dataPath)
end

% set remaining missing fields in exptPre to default values
exptPre = set_exptDefaults(exptPre);

%% run mini experiment and determine LPC order based on trials
goodLPC = 'no';
while strcmp(goodLPC, 'no')
    %run pre-experiment data collection
    exptPre = run_measureFormants_audapter(exptPre, exptPre.audapterParams.fb);

    % Check LPC order
    exptPre = check_audapterLPC(exptPre.dataPath); % check that they're being tracked right
    hGui = findobj('Tag','check_LPC');
    waitfor(hGui);
    exptPre.fmtMeans = calc_vowelMeans(exptPre.dataPath);

    % Confirm file exists. Ask user if it's OK
    if exist(fullfile(exptPre.dataPath, 'nlpc.mat'), 'file')
        goodLPC = askNChoiceQuestion('Was the LPC check recording good?', {'yes' 'no'});
    else
        fprintf('\nRe-running LPC_check section. Couldn''t find an nlpc.mat file in %s\n', exptPre.dataPath)
    end
end

%% save it
%set lpc order
load(fullfile(exptPre.dataPath,'nlpc'),'nlpc') 
p.nLPC = nlpc;
if isfield(expt, 'audapterParams')
    expt.audapterParams = add2struct(expt.audapterParams, p);
else
    expt.audapterParams = p;
end

%Get vowel formant means from expt
exptPre.fmtMeans = calc_vowelMeans(exptPre.dataPath);

% Save all info in the pre, switch back to top level expt
exptfile = fullfile(exptPre.dataPath,'expt.mat');
pre.expt = exptPre;
save(exptfile, '-struct', 'pre');

exptfile = fullfile(expt.dataPath,'expt.mat');
save(exptfile, 'expt');
fprintf('\nSaved expt file with LPC order: %s\n', exptfile);

end %EOF
