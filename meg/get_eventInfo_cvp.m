function [eventInfo] = get_eventInfo_cvp(dataPath)
%GET_EVENTINFO_CVP  Get event info for center and periph trials.
%   GET_EVENTINFO_CVP(DATAPATH) uses trial information from fdata_vowel.mat
%   to construct eventInfo grouped by center and peripheral trials.
%   Because fdata_vowel has bad trials already excluded, only good trials
%   are part of the event structure.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

load(fullfile(dataPath,'fdata_vowel.mat'));
vowels = fieldnames(fmtdata.mels);

center = cellfun(@(fn) fmtdata.mels.(fn).first50ms.center33, vowels, 'UniformOutput',false);
center = cat(2,center{:});
periph = cellfun(@(fn) fmtdata.mels.(fn).first50ms.periph33, vowels, 'UniformOutput',false);
periph = cat(2,periph{:});

eventInfo(1).name = 'speak_center';
eventInfo(1).color = [.1 .75 0];
eventInfo(1).trialinds = center;

eventInfo(2).name = 'speak_periph';
eventInfo(2).color = [1 0 0];
eventInfo(2).trialinds = periph;

eventInfo(3).name = 'listen_center';
eventInfo(3).color = [.1 .75 0];
eventInfo(3).trialinds = center;

eventInfo(4).name = 'listen_periph';
eventInfo(4).color = [1 0 0];
eventInfo(4).trialinds = periph;