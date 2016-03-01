function [] = gen_fdata(dataPath,condtype,dataValsStr)
%GEN_FDATA  Calculate formant averages on a dataVals object.
%   GEN_FDATA(DATAPATH,CONDTYPE,DATAVALSSTR) loads a subject's expt and
%   dataVals objects from DATAPATH and calls CALC_FDATA to calculate
%   formant, pitch, amplitude and duration averages.  The output is saved
%   to DATAPATH/fdata_[CONDTYPE].mat, where CONDTYPE is 'vowel' (to group
%   by vowel) or 'cond' (to group by condition, e.g. pitch).

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(condtype), condtype = 'vowel'; end
if nargin < 3 || isempty(dataValsStr), dataValsStr = 'dataVals'; end

load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,dataValsStr));

[fmtdata,f0data,ampldata,durdata,trialinds] = calc_fdata(expt,dataVals,condtype); %#ok<ASGLU>

savefile = fullfile(dataPath,sprintf('fdata_%s%s.mat',condtype,dataValsStr(9:end)));
bSave = savecheck(savefile);
if bSave
    save(savefile,'fmtdata','f0data','ampldata','durdata','trialinds');
    fprintf('fdata saved to %s.\n',savefile)
end
