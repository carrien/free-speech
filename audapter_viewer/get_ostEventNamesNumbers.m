function [varargout] = get_ostEventNamesNumbers(trackingFileDir,trackingFileName,events,bNames,bNumbers,bOrdinal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% An extract from gen_ostUserEvents_timeAdapt that will give you the event name, the ost status number, and/or the ordinal
% value of the event (first event, second event, etc.) of a given set of events. 
% 
% Inputs: 
% - exptName: 'timeAdapt', 'timeAdapt4', etc. 
% - stimWord: 'capper', 'gapper', etc. Assumes capperWorking.ost filenaming convention (in function call to get_ost)
% - events: the set of events you want to get info about. Can be something like {'cBurst' 'erEnd' 'trigger'} or [2 4
% 8]---ignores events that don't exist. Only works with either known event names or ost statuses, does not work with event
% orders (so you can't ask it for the name of the first event, for example) 
% - bNames: whether you want it to return names
% - bNumbers: whether you want it to return numbers
% - bOrdinal: whether you want it to return the order of the event (will return as [1 2 3] for first, second, third) 
% 
% Order of return is 1. names 2. numbers 3. orders
% 
% Initiated RPK 2020-03-05 as an overly elaborate fix to a problem in set_signalOutUserEvents caused by a change in
% gen_ostUserEvents that affects the structure of origOstTimes in data
% CWN 2020-07-27 made compatible with dipSwitch
% RPK 2020-11-12 updated argument structure for changes in get_pcf
% CWN 2021-04 added simonSingleWord
% 
% RPK 2021-05 added timeWrap; changed exptName and stimWord to trackingFileDir and trackingFileName (should be approximately
% the same as previously and should not break any compatibility). This function is now called by audapter_viewer to get
% tooltips for the OST reference lines. 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error
if nargin < 1 || isempty(trackingFileDir), trackingFileDir = 'experiment_helpers'; end
if nargin < 2 || isempty(trackingFileName), trackingFileName = 'measureFormants'; end

% Input argument 3's default is determined after all the information has been pulled!!!!

if (nargin < 4 || isempty(bNames)) && ~iscell(events)
    bNames = 1; 
elseif (nargin < 4 || isempty(bNames)) && iscell(events)
    bNames = 0; 
end

if (nargin < 5 || isempty(bNumbers)) && ~isnumeric(events)
    bNumbers = 1; 
elseif (nargin < 5 || isempty(bNumbers)) && isnumeric(events)
    bNumbers = 0; 
end

if nargin < 6 || isempty(bOrdinal), bOrdinal = 0; end

%% Get OST event information 

% Get the list of OST statuses, convert to a numeric vector 
eventNos = str2double(get_ost(trackingFileDir, trackingFileName, 'list')); 

% Pre-defined available events for stimulus words. Covers "capper" and "a capper" types. 
% For each new experiment, make a new elseif statement below
if strcmp(trackingFileDir, 'timeAdapt')
    if strcmp(trackingFileName,'capper')
%         eventNos = str2double(get_ost(trackingFileDir, trackingFileName, 'list')); % Surely you can just do this once for all?
        eventNames = {'v1Start' 'cStart' 'cBurst' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
%         eventNames = eventNames(end-(length(eventNos) - 1):end); % This seems... redundant? 
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
        triggerName = eventNames{triggerNo == eventNos}; 
    elseif strcmp(trackingFileName, 'gapper') 
        eventNames = {'v1Start' 'cStart' 'cBurst' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
        triggerName = eventNames{triggerNo == eventNos}; 
    elseif strcmp(trackingFileName, 'sapper')
        eventNames = {'v1Start' 'cStart' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
        triggerName = eventNames{triggerNo == eventNos}; 
    elseif strcmp(trackingFileName, 'zapper')
        eventNames = {'v1Start' 'cStart' 'v2Start' 'pStart' 'erStart' 'erEnd'}; 
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
        triggerName = eventNames{triggerNo == eventNos}; 
    end

elseif strcmp(trackingFileDir, 'dipSwitch')
    if strcmp(trackingFileName, 'tipper')
        eventNames = {'cBurst' 'vStart' 'pStart' 'erStart' 'erEnd'};
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
        triggerName = eventNames{triggerNo == eventNos};
    elseif strcmp(trackingFileName, 'dipper')
        eventNames = {'cBurst' 'vStart' 'pStart' 'erStart' 'erEnd'};
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
        triggerName = eventNames{triggerNo == eventNos};
    end

% Adding for timitate. Just using uniform names because all I really care about is vStart to codaStart and it would be nice
% to not have to make dataVals more complicated than it has to be
elseif strcmp(trackingFileDir, 'timitate')
    if strcmp(trackingFileName, 'DTum')
        % VOT measure needs different events
        eventNames = {'cBurst' 'vStart' 'codaStart' 'codaRelease'};         
    else        
        eventNames = {'onsStart' 'vStart' 'codaStart' 'codaRelease'};        
    end
    triggerNo = get_pcf(trackingFileDir, trackingFileName, 'space', 2, 'stat'); 
    triggerName = eventNames{triggerNo == eventNos};
    
    
% simonSingleWord
elseif strcmp(trackingFileDir, 'simonSingleWord')
    eventNames = {'v1Start' 'v1End' 'v2Start' 'v2End'};
    triggerNo = get_pcf(trackingFileDir, trackingFileName, 'space', 4, 'stat');
    triggerName = eventNames{triggerNo == eventNos};
    
% simonMultisyllable
elseif strcmp(trackingFileDir, 'simonMultisyllable')
    eventNames = {'v1Start' 'v1End' 'v2Start' 'v2End'};
    triggerNo = get_pcf(trackingFileDir, trackingFileName, 'space', 4, 'stat');
    triggerName = eventNames{triggerNo == eventNos};

elseif strcmp(trackingFileDir, 'simonMultisyllable_v2')
    eventNames = {'v1Start' 'v1End' 'v2Start' 'v2End'};
    triggerNo = get_pcf(trackingFileDir, trackingFileName, 'space', 4, 'stat');
    triggerName = eventNames{triggerNo == eventNos};
    
% timeWrap
elseif strcmp(trackingFileDir, 'timeWrap')
    if strcmp(trackingFileName, 'tipper') || strcmp(trackingFileName, 'tapper')
        eventNames = {'mStart' 'v1Start' 'tClosure' 'tBurst' 'v2Start' 'pStart' 'erStart' 'erEnd'};
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial');
        triggerName = eventNames{triggerNo == eventNos};
    elseif strcmp(trackingFileName, 'zipper') || strcmp(trackingFileName, 'zapper')
        eventNames = {'mStart' 'v1Start' 'zStart' 'v2Start' 'pStart' 'erStart' 'erEnd'};
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial');
        triggerName = eventNames{triggerNo == eventNos};
    elseif strcmp(trackingFileName, 'sipper') || strcmp(trackingFileName, 'sapper')
        eventNames = {'mStart' 'v1Start' 'sStart' 'v2Start' 'pStart' 'erStart' 'erEnd'};
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial');
        triggerName = eventNames{triggerNo == eventNos};
    elseif strcmp(trackingFileName, 'shopper') || strcmp(trackingFileName, 'shaper')
        eventNames = {'mStart' 'v1Start' 'shStart' 'v2Start' 'pStart' 'erStart' 'erEnd'};
        eventNames = eventNames(end-(length(eventNos) - 1):end);
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial');
        triggerName = eventNames{triggerNo == eventNos};        
    elseif strcmp(trackingFileName, 'copper') || strcmp(trackingFileName, 'caper')
        eventNames = {'mStart' 'v1Start' 'cClosure' 'cBurst' 'v2Start' 'pStart' 'erStart' 'erEnd'};
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial');
        triggerName = eventNames{triggerNo == eventNos};
    elseif strcmp(trackingFileName, 'durTest')
        eventNames = {'110soft' '220loud' 'noise1' '220soft' '110loud' 'noise2' 'end'}; 
        triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial');
        triggerName = eventNames{triggerNo == eventNos};
    end
    
elseif any(strcmp(strsplit(trackingFileDir, filesep), 'cerebTimeAdapt'))
    eventNames = {'vStart' 'sStart' 'tStart' 'tEnd'}; 
    triggerNo = 2; 
    triggerName = eventNames{triggerNo == eventNos};
    
elseif any(strcmp(strsplit(trackingFileDir, filesep), 'taimComp'))
    if strcmp(trackingFileName, 'buyYogurt')
        eventNames = {'wiStart', 'bStart', 'aiStart', 'gStart'}; %{'wiStart', 'wait', 'bStart', 'aiStart', 'wait', 'dStart'};
        triggerNo = 6;
        triggerName = eventNames{triggerNo == eventNos};
    else
        % the other one is Daid (takes care of both words) 
        eventNames = {'wiStart', 'bStart', 'aiStart', 'dStart'};
        triggerNo = 6;
        triggerName = eventNames{triggerNo == eventNos};
    end
    
elseif strcmp(trackingFileDir, 'experiment_helpers') || strcmp(trackingFileName, 'measureFormants')
    eventNames = {'vStart' 'vEnd'};
    triggerNo = get_pcf(trackingFileDir, trackingFileName, 'space', 2, 'stat');
    triggerName = eventNames{triggerNo == eventNos};
    
end


% Check if vars exist. If not, then assign defaults ("ost_2")
if ~exist('eventNames', 'var')
    warning('Using default stimulus word events')
    eventNames = cell(1,length(eventNos)); 
    for i = 1:length(eventNos)
        eventNames{i} = ['ost' num2str(eventNos(i))];
    end
    triggerNo = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); 
    triggerName = eventNames{triggerNo == eventNos}; 
end



%% Fetch just the outputs asked for

% Integrate "events" arg: if empty, just feed back all the events 
if nargin < 3 || isempty(events), events = eventNos; end

% Check that the specified events actually exist in the list
if iscell(events) % If you input event names
    % Check for "trigger" and convert if exists
    if ismember('trigger',events)
        events{strcmp('trigger',events)} = triggerName; 
    end    
    badEvents = events(~ismember(events,eventNames)); 
    events = events(ismember(events,eventNames)); 
    if ~isempty(badEvents)
        warning('Event(s) %s ignored (does not exist for word)\n', [sprintf('%s, ', badEvents{1:end-1}), badEvents{end}])
    end
    ostEvents = eventNos(ismember(eventNames,events)); 
    ostEventNames = eventNames(ismember(eventNames,events)); % This does the job of sorting 
    ostOrder = find(ismember(eventNames,events)); 
else % If you input(ted?) event numbers 
    badEvents = events(~ismember(events,eventNos)); 
    events = events(ismember(events,eventNos));
    if ~isempty(badEvents)
        badEvents = num2cell(badEvents); 
        warning('Event(s) %s ignored (does not exist for word)\n', [sprintf('%d, ', badEvents{1:end-1}), num2str(badEvents{end})])
    end
    ostEvents = eventNos(ismember(eventNos,events));
    ostEventNames = eventNames(ismember(eventNos,events)); 
    ostOrder = find(ismember(eventNos,events)); 
end

outputIx = 1; 
if bNames
    varargout{outputIx} = ostEventNames; 
    outputIx = outputIx + 1; 
end

if bNumbers
    varargout{outputIx} = ostEvents; 
    outputIx = outputIx + 1; 
end

if bOrdinal
    varargout{outputIx} = ostOrder; 
end

end
