function [] = gen_distinds(exptName,snum,subdirname,fdataStr,acoustparam)
%GEN_DISTINDS  Calculate formant averages on an fdata object.
%   GEN_DISTINDS loads a subject (SNUM)'s expt and fdata objects and calls
%   GET_DISTINDS to calculate each trial's distance from the mean. The
%   output is saved to distinds_all.mat in the subject's data directory.
%   FDATASTR specifies the type of fdata object (e.g. 'fdata_vowel',
%   'fdata_cond') and ACOUSTPARAM specifies the acoustic parameter (e.g.
%   'f0data', 'fmtdata', 'ampldata', or 'durdata').
%
%   See also GET_DISTINDS_1VOWEL.

if nargin < 3 || isempty(subdirname) && strcmp(exptName,'mvSIS')
    subdirname = 'speak';
elseif nargin < 3 || isempty(subdirname) && strcmp(exptName,'cat')
    subdirname = fullfile('pert','formant_analysis');
end

dataPath = getAcoustSubjPath(exptName,snum,subdirname);

fdata = load(fullfile(dataPath,fdataStr));
[distinds,~] = get_distinds(fdata.(acoustparam)); %#ok<ASGLU>
savefile = fullfile(dataPath,sprintf('distinds_%s_%s.mat',fdataStr,acoustparam));

bSave = savecheck(savefile);
if bSave, save(savefile,'distinds'); end