function [] = gen_fdata(exptName,snum,condtype,dataValsStr,subdirname,bGoodTrialsOnly)
%GEN_FDATA  Calculate formant averages on a dataVals object.
%   GEN_FDATA(EXPTNAME,SNUM,CONDTYPE,DATAVALSSTR,SUBDIRNAME) loads a
%   subject (SNUM)'s expt and dataVals objects and calls CALC_FDATA to
%   calculate formant averages.  The output is saved to
%   fdata_[CONDTYPE].mat in the subject's formant_analysis directory, where
%   CONDTYPE is 'vowel' (to group by vowel) or 'cond' (to group by
%   condition, e.g. pitch).

if nargin < 3 || isempty(condtype), condtype = 'vowel'; end
if nargin < 4 || isempty(dataValsStr), dataValsStr = 'dataVals'; end
if nargin < 5 && strcmp(exptName,'mvSIS')
    subdirname = 'speak';
elseif nargin < 5 && strcmp(exptName,'cat')
    subdirname = 'pert';
elseif nargin < 5
    subdirname = [];
end
if nargin < 6 || isempty(bGoodTrialsOnly), bGoodTrialsOnly = 0; end

dataPath = getAcoustSubjPath(exptName,snum,subdirname);
load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,dataValsStr));

[fmtdata,f0data,ampldata,durdata,trialinds] = calc_fdata(expt,dataVals,condtype); %#ok<ASGLU,NASGU>

savefile = fullfile(dataPath,sprintf('fdata_%s%s.mat',condtype,dataValsStr(9:end)));
bSave = savecheck(savefile);
if bSave, save(savefile,'fmtdata','f0data','ampldata','durdata','trialinds'); end