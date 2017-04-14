function [eventInfo] = get_cvp_eventInfo(dataPath)
%GET_CVP_EVENTINFO  Get event info for center and periph trials.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

load(fullfile(dataPath,'fdata_vowel.mat'));

eventInfo(1).name = 'speak_center';
eventInfo(1).color = [.1 .75 0];
eventInfo(1).trialinds = [fmtdata.mels.i.first50ms.center33 fmtdata.mels.E.first50ms.center33 fmtdata.mels.ae.first50ms.center33];

eventInfo(2).name = 'speak_periph';
eventInfo(2).color = [1 0 0];
eventInfo(2).trialinds = [fmtdata.mels.i.first50ms.periph33 fmtdata.mels.E.first50ms.periph33 fmtdata.mels.ae.first50ms.periph33];

eventInfo(3).name = 'listen_center';
eventInfo(3).color = [.1 .75 0];
eventInfo(3).trialinds = eventInfo(1).trialinds;

eventInfo(4).name = 'listen_periph';
eventInfo(4).color = [1 0 0];
eventInfo(4).trialinds = eventInfo(2).trialinds;