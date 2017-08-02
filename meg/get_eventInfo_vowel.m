function [eventInfo] = get_eventInfo_vowel(dataPath)
%GET_EVENTINFO_CVP  Get event info for center and periph trials.
%   GET_EVENTINFO_CVP(DATAPATH) uses trial information from fdata_vowel.mat
%   to construct eventInfo grouped by center and peripheral trials.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

load(fullfile(dataPath,'expt.mat'));
%load(fullfile(dataPath,'dataVals.mat'));
%goodtrials = [dataVals(~[dataVals.bExcl]).token];

eventInfo(1).name = 'listen_i';
eventInfo(1).color = [.3 1 0];
eventInfo(1).trialinds = expt.inds.vowels.i;
%eventInfo(1).trialinds = intersect(expt.inds.vowels.i,goodtrials);

eventInfo(2).name = 'listen_E';
eventInfo(2).color = [1 0 0];
eventInfo(2).trialinds = expt.inds.vowels.E;
%eventInfo(2).trialinds = intersect(expt.inds.vowels.E,goodtrials);

eventInfo(3).name = 'listen_ae';
eventInfo(3).color = [0 .3 1];
eventInfo(3).trialinds = expt.inds.vowels.ae;
%eventInfo(3).trialinds = intersect(expt.inds.vowels.ae,goodtrials);