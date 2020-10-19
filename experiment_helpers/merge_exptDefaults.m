function [expt] = merge_exptDefaults(expt)
%MERGE_EXPTDEFAULTS  Get parameters for default experiment.
%   MERGE_EXPTDEFAULTS(EXPT) replaces missing fields in EXPT with default
%   values for those fields.

if nargin < 1 || isempty(expt), expt = struct; end

%% define default experiment
expt_default.name = 'default';
if isfield(expt,'snum') % use snum if already defined
    expt.snum = get_snum(expt.snum);
else
    expt_default.snum = get_snum;
end
if isfield(expt,'gender') % use gender if already defined
    expt.gender = get_gender(expt.gender);
else
    expt_default.gender = get_gender;
end

expt_default.conds = {'test'};
expt_default.words = {'bed'};
expt_default.vowels = {'eh'};
expt_default.colors = {'white'};
expt_default.colorvals = {[1 1 1]};

expt_default.nblocks = 1;
expt_default.ntrials_per_block = 10;

% stimulus timing parameters, in seconds
expt_default.timing.stimdur = 1.5;            % time of recording
expt_default.timing.visualfbdur = 0.5;      % time visual feedback is shown
expt_default.timing.interstimdur = 0.5;     % minimum time between stims
expt_default.timing.interstimjitter = 0.5;  % maximum extra time between stims (jitter)

% duration tracking parameters
expt_default.durcalc.min_dur = .25;         %
expt_default.durcalc.max_dur = .5;
expt_default.durcalc.ons_thresh = 0.3;
expt_default.durcalc.offs_thresh = 0.4;

% instructions
expt_default.instruct.introtxt = {'Read each word out loud as it appears.' '' 'Press the space bar to continue when ready.'};
expt_default.instruct.txtparams.Color = 'white';
expt_default.instruct.txtparams.FontSize = 45;
expt_default.instruct.txtparams.HorizontalAlignment = 'Center';

%% copy missing fields
expt_fields = fieldnames(expt);
expt_default_fields = fieldnames(expt_default);
missing_fields = setdiff(expt_default_fields,expt_fields);

for f=1:length(missing_fields)
    fieldname = missing_fields{f};
    expt.(fieldname) = expt_default.(fieldname);
end

%% set missing fields that depend on existing params
expt_default = expt;
expt_default.ntrials = expt_default.nblocks * expt_default.ntrials_per_block;
expt_default.allConds = ones(1,expt_default.ntrials);
expt_default.allWords = ones(1,expt_default.ntrials);
expt_default.allVowels = ones(1,expt_default.ntrials);
expt_default.allColors = ones(1,expt_default.ntrials);
expt_default.listWords = expt_default.words(expt_default.allWords);
expt_default.listConds = expt_default.conds(expt_default.allConds);
expt_default.listWords = expt_default.words(expt_default.allWords);
expt_default.listVowels = expt_default.vowels(expt_default.allWords);
expt_default.listColors = expt_default.colors(expt_default.allColors);

expt_default.shiftMags = zeros(1,expt_default.ntrials);
expt_default.shiftAngles = zeros(1,expt_default.ntrials);

%% copy missing fields
expt_fields = fieldnames(expt);
expt_default_fields = fieldnames(expt_default);
missing_fields = setdiff(expt_default_fields,expt_fields);

for f=1:length(missing_fields)
    fieldname = missing_fields{f};
    expt.(fieldname) = expt_default.(fieldname);
end

%% calculate trial indices
expt.inds = get_exptInds(expt,{'conds', 'words', 'vowels', 'colors'});