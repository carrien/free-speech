function [durInfo] = get_segmentDuration(expt, data, startStatus, endStatus, origCalc)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Script to get the time interval between two OST statuses and put into a runningData structure of length nTrials
% 
% inputs: 
% 1. data: Audapter data. Can be from a single trial run of Audapter or more (e.g., the entire dataset from a pretest phase) 
% 2. ostStartStatus: the status that defines the beginning of the time interval of interest
% 3. ostEndStatus: the status that defines the end of the time interval of interest
% 4. bOstTime: if 
% 
% Outputs: 
% 1. allDurs: a structure with the duration information from every trial, and whether or not the trial was good
% 2. runningDurs: a subset of allData that is as long as nTrials (contains the last nTrials good trials) 
% 3. durInfo: that trial's durInfo so you can tack it into the trial's data structure (this is so that you can get multiple
% durations by calling the script multiple times) 
% 
% Initiated RPK 2021-02-23
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error

% Default arguments. Using as if measureFormants were the OST 
if nargin < 2 || isempty(data)
    fprintf('Loading data... \n')
    load(fullfile(expt.dataPath, 'data.mat')); 
    fprintf('Done.\n')
end

if nargin < 3 || isempty(startStatus), startStatus = 2; end
if nargin < 4 || isempty(endStatus), endStatus = 4; end
if nargin < 5 || isempty(origCalc), origCalc = 'orig'; end

if isfield(expt, 'trackingFileDir')
    trackingFileDir = expt.trackingFileDir; 
elseif isfield(expt, 'trackingFileLoc')
    trackingFileDir = expt.trackingFileLoc; 
else
    trackingFileDir = []; % defaults to experiment_helpers in the function where it's called
end

if isfield(expt, 'trackingFileName')
    trackingFileName = expt.trackingFileName; 
else
    trackingFileName = []; % defaults to measureFormants
end

%%
for i = 1:length(data)
    % Get times of transitions to starting and ending ost statuses
    if strcmp(origCalc, 'orig')
        ost_stat = data(i).ost_stat; 
    elseif strcmp(origCalc, 'calc')
        if isfield(data, 'ost_calc')
            ost_stat = data(i).ost_calc; 
        elseif isfield(data, 'calcOST')
            ost_stat = data(i).calcOST; 
        else 
            ost_stat = data(i).ost_stat; % if you haven't recalculated yet
        end
    end
    ostStartIx = find((ost_stat == startStatus), 1); 
    ostEndIx = find((ost_stat == endStatus), 1); 
    
    % If either of the statuses was never achieved
    if isempty(ostStartIx) || isempty(ostEndIx)
        durInfo(i).ostDur = NaN; 
        durInfo(i).realDur = NaN; 
        durInfo(i).startStatusTime = NaN;  
        durInfo(i).endStatusTime = NaN; 
        durInfo(i).adjusted_startStatusTime = NaN; 
        durInfo(i).adjusted_endStatusTime = NaN; 
        durInfo(i).bBadTrack = 1;  
        continue; 
    end
    
    % Turn into time
    timeMultiplier = data(i).params.frameLen / data(i).params.sr;
        
    % Get buffers for statuses. Uses working version, assumes that it has been changed to participant-specific params
    [startStatusHeur, startStatusParam1, startStatusParam2, startStatusParam3] = get_ost(trackingFileDir, trackingFileName, startStatus, 'working');
    if contains(startStatusHeur,'STRETCH')
        % experimenting here. For these kinds of statuses it is not great to use the buffer
        startStatus_buffer = 0; 
%         startStatus_buffer = startStatusParam1 * expt.audapterParams.frameLen / expt.audapterParams.sr; 
    elseif ~isnan(startStatusParam3) && ~strcmp(startStatusParam3,'NaN')
        % If your third status isn't a NaN, then you've got a third parameter, which in our case is always duration
        startStatus_buffer = startStatusParam3; 
    else
        startStatus_buffer = startStatusParam2; 
    end
    
    [endStatusHeur, endStatusParam1, endStatusParam2, endStatusParam3] = get_ost(trackingFileDir, trackingFileName, endStatus, 'working');     
    if contains(endStatusHeur,'STRETCH')
        endStatus_buffer = 0; 
%         endStatus_buffer = endStatusParam1 * expt.audapterParams.frameLen / expt.audapterParams.sr; 
    elseif ~isnan(endStatusParam3) && ~strcmp(endStatusParam3,'NaN')
        % If your third status isn't a NaN, then you've got a third parameter, which in our case is always duration
        endStatus_buffer = endStatusParam3; 
    else
        endStatus_buffer = endStatusParam2; 
    end
    
    % Outputs
    durInfo(i).startStatusTime = ostStartIx * timeMultiplier; 
    durInfo(i).endStatusTime = ostEndIx * timeMultiplier; 
    durInfo(i).adjusted_startStatusTime = ((ostStartIx * timeMultiplier) - startStatus_buffer); 
    durInfo(i).adjusted_endStatusTime = ((ostEndIx * timeMultiplier) - endStatus_buffer); 
    durInfo(i).ostDur = durInfo(i).endStatusTime - durInfo(i).startStatusTime; 
    durInfo(i).realDur = durInfo(i).adjusted_endStatusTime - durInfo(i).adjusted_startStatusTime; 
    durInfo(i).bBadTrack = 0; 
    
end

