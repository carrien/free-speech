function [eventInfo] = get_eventInfo_cvp(dataPath,cond,othercond)
%GET_EVENTINFO_CVP  Get event info for center and periph trials.
%   GET_EVENTINFO_CVP(DATAPATH,COND) uses trial information from
%   fdata_vowel.mat to construct eventInfo grouped by center and peripheral
%   trials. COND determine which events will be tracked and can be 'speak',
%   'listen', or 'both'. Because fdata_vowel has bad trials already
%   excluded, only good trials are part of the event structure.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(cond), cond = 'both'; end
if nargin < 3 || isempty(othercond), othercond = ''; end

load(fullfile(dataPath,'fdata_vowel.mat'));
vowels = fieldnames(fmtdata.mels);

center = cellfun(@(fn) fmtdata.mels.(fn).first50ms.center33, vowels, 'UniformOutput',false);
center = cat(2,center{:});
periph = cellfun(@(fn) fmtdata.mels.(fn).first50ms.periph33, vowels, 'UniformOutput',false);
periph = cat(2,periph{:});

eventInfo = struct([]);
conds = {'speak','listen'};
for c=1:length(conds)
    thiscond = conds{c};
    if any(strcmp(cond,{thiscond,'both'})) % if condition matches this cond (or is 'both')
        len = length(eventInfo);
        eventInfo(len+1).name = sprintf('%s%s_Center',othercond,thiscond);
        eventInfo(len+1).color = [.1 .75 0];
        eventInfo(len+1).trialinds = center;
        eventInfo(len+2).name = sprintf('%s%s_Periph',othercond,thiscond);
        eventInfo(len+2).color = [1 0 0];
        eventInfo(len+2).trialinds = periph;
    end
end
