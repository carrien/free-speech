function [varargout] = get_pcf(audFileDir, audFileName, timeSpace, ostStatus, varargin)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% MAJOR VERSION CHANGE RPK 10/29/2020 after change in set_pcf
%
% This script allows the retrieval of information from a single line of a working PCF file. This line can be either from the
% time warping lines or from the formant perturbation lines. You can retrieve a whole line or some subset of parameters. 
% 
%
% Input arguments:
% 1.) audFileLoc (formerly exptName): name of the folder (path from current-studies) where the PCF is found,
% e.g. 'experiment_helpers', 'timeAdapt'. Defaults to 'experiment_helpers'
% 
% 2.) audFileName (formerly word): name of the PCF file that is being used. Do NOT include Working.pcf, only
% the main name (e.g. measureFormants, sapper). Defaults to 'measureFormants'
% 
% 3.) timeSpace (new addition): whether you are editing the time events or the formant (space) events, options
% 'time' and 'space'. Default is 'time' because under this roof we default to temporal concerns
%
% 4.) ostStatus (new addition): the OST status that you would like to get information about
% --- use a number (as a double) if you know the OST status you're looking for. You'll always use this for
% "space" warping lines. 
% --- For time warping you can use either a double (give me the line that starts with OST status 2) or a
% string ('2' meaning "give me the information on the second time warping line"). If you do the latter you
% will get a notification that this is how the script is interpreting it. 
% --- If you have a timewarping line that is specified ONLY by tBegin (i.e., it is not triggered by an OST status), specify 
% its number in the order of time warping events (e.g. it's the second time warping event) as a string: '2' 
% 
% 5.) varargin (preserved): the parameter(s) that you would like to retrieve. One argument per desired parameter 
% --- time warping options: ostStat_initial, tBegin, rate1, dur1, durHold, rate2, perturb
% --- formant warping options: stat (probably pointless), pitchShift, gainShift, fmtPertAmp, fmtPertPhi
% --- can also do 'all' which will just give you the entire list, including the initial OST status
%
% Order of arguments in function: "in AUDFILELOC/AUDFILENAMEWorking.pcf, I want to get the TIME/SPACE
% information for OSTSTATUS/WARPLINE NUMBER. I want to get VARIOUS PARAMETERS' VALUES. 
%
% e.g. 
%
% get_pcf('timeAdapt', 'sapper', 'time', 4, 'rate1', 'dur1') *** Note you can also do {'rate1' 'dur1'}, either is
% interpretable
% get_pcf({}, {}, 'space', 6, 'all') 
% get_pcf('timeAdapt', 'capper', [], '1', 'ostStat_initial') (give me the ostStatus that triggers the first
% time warping event in timeAdapt's capper PCF) 
%
% Output arguments:
% 1.) varargout: a vector of values in the order you requested them
%
% Originally a nested function in run_sAdapt_audapter
% originated as timeAdapt_pcfEdit by CWN 
% transfer to refreshTimeWarpPCF by RPK
%
% last major edit RPK 2019/9/24
% last minor edit CWN 2020/7/22, updated args for refreshWorkingCopy call
% last minor edit RPK 2020/09/11, updated defaults
% last major edit RPK 2020/10/28, change to flexible retrieval
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

dbstop if error 

%% Set up argument defaults, basic information

if nargin < 1 || isempty(audFileDir), audFileDir = 'experiment_helpers'; end % this will have to be updated whenever we decide where to put measureFormantsWorking.pcf
if nargin < 2 || isempty(audFileName), audFileName = 'measureFormants'; end
if nargin < 3 || isempty(timeSpace), timeSpace = 'time'; end
if ~strcmp(timeSpace, 'time') && ~strcmp(timeSpace, 'space')
    warning('Third argument should be ''time'' or ''space''. Are you using an old argument configuration of get_pcf? Check argument structure against new version (implemented November 2020).')
    return
end
if nargin < 4 || isempty(ostStatus)
    allStatuses = get_ost(audFileDir, audFileName, 'list', 'working'); % Get the list of possible statuses 
    lastStatus = allStatuses{end}; 
    lastStatus = str2double(lastStatus); 
    ostStatus = NaN; 
    while isnan(ostStatus)
        ostStatus = input(['What OST status number would you like to use to look up the PCF? Max status is ' num2str(lastStatus) ': ']); 
        if isempty(ostStatus) || ~ismember(ostStatus, [0:lastStatus])
            ostStatus = NaN; 
            fprintf('Invalid status. Please enter a number between 0 and %d.\n', lastStatus)
        end
    end
end

%% File and editing information
trackingPath = get_trackingFilePath(audFileDir, audFileName); 
% if strcmp(audFileName, 'measureFormants') || strcmp(audFileDir, 'experiment_helpers') % So theoretically you could be doing some OTHER PCF file that is in experiment_helpers
%     trackingPath = fullfile(get_gitPath('free-speech'), audFileDir); % could potentially hard-code this to experiment_helpers but... 
% elseif isfolder(audFileDir)
%     if contains(audFileDir,'/') || contains(audFileDir,'\')
%         trackingPath = audFileDir;
%     else
%         trackingPath = fullfile(get_gitPath('current-studies'), audFileDir);
%     end
% else
%     trackingPath = fullfile(get_gitPath('current-studies'), audFileDir); % ['C:\Users\Public\Documents\software\current-studies\' audFileLoc]; 
% end

pcfName = [audFileName 'Working.pcf']; 
pcfFile = fullfile(trackingPath,pcfName);

% If a working copy doesn't exist, make one
if exist(pcfFile,'file') ~= 2
    refreshWorkingCopy(audFileDir, audFileName,'pcf');
end

% Open file
fid = fopen(pcfFile,'r');

% Load file line by line into structure finfo
tline = fgetl(fid);
i = 1;
clear finfo
finfo{i} = tline;
% Gets the first line into split_finfo
split_tline = strsplit(tline, ' '); 
firstChars{i} = split_tline{1}; 
splitFinfo_ascii{i} = double(firstChars{i}); 
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    finfo{i} = tline;
    
    % Split line on space. Section header lines will be a single integer. 
    if tline ~= -1 % the end is this numeric and can't split
        split_tline = strsplit(tline, ' '); 
        firstChars{i} = split_tline{1}; 
        splitFinfo_ascii{i} = double(firstChars{i}); 
    end
end

% Close file
fclose(fid);

% Find which lines demarcate the beginning of the timewarping sections and the spatial warping sections
% Should be a line that has a single integer. Have to convert to ascii to verify that is not '4,' (for
% example, as str2double on that produces 4, which is an integer) and to also include '10' which is more than
% a single character

c = 1; 
for ix = 1:length(splitFinfo_ascii)
    bAllDigits = splitFinfo_ascii{ix} <= 57 & splitFinfo_ascii{ix} >= 48; % all characters in the split section have to be digits (no commas, no #, etc.) 
    if bAllDigits
        demarcaterIx(c) = ix; 
        c = c+1;
    end
end

% Abort if you don't have two sections. 
if length(demarcaterIx) ~= 2
    warning('Something is wrong with your PCF file. Incorrect number of warping sections. Stopping script.')
return
end

% Get line ranges for the time/space sections
switch timeSpace
    case 'time'
        nTimeEvents = str2double(firstChars{demarcaterIx(1)}); % Find number of time events
        if nTimeEvents == 0 
            warning('There are no time warping events. Stopping script.')
            varargout{nargout} = [];
            return
        else
            startLine = demarcaterIx(1) + 1; % editable information starts on the next line
            endLine = startLine + (nTimeEvents - 1); % and this section will end after nTimeEvent lines
        end
    case 'space'
        nWarpOsts = str2double(firstChars{demarcaterIx(2)}); % Find number of OST events
        startLine = demarcaterIx(2) + 1; 
        endLine = startLine + (nWarpOsts - 1); 
end


% Find the line that matches the ost status you're trying to edit
fileLines = startLine:endLine;
if ischar(ostStatus)
    if strcmp(timeSpace, 'time')
        lineloc = startLine + (str2double(ostStatus) - 1); 
        if lineloc < startLine || lineloc > endLine
            warning('You''ve specified time warp line %s but there are only %d time events. Stopping script.', ostStatus, nTimeEvents)
            return
        end
        components = strsplit(finfo{lineloc},','); 
    else
        warning('Specifying OST status as a string is reserved for time warping lines with no OST status trigger. Option ''space'' chosen; stopping script.')
        return
    end

else
    for i = 1:length(fileLines)
        warplines{i} = strsplit(finfo{fileLines(i)},',');
        ostOfComponent = str2double(warplines{i}{1}); 
        if ostOfComponent == ostStatus
            lineloc = fileLines(i); 
            components = warplines{i}; 
            break
        elseif i == length(fileLines) && ostOfComponent ~= ostStatus
            allStatuses = get_ost(audFileDir, audFileName, 'list', 'working'); % Get the list of possible statuses 
            lastStatus = allStatuses{end}; 
            lastStatus = str2double(lastStatus); 
            if strcmp('space', timeSpace) && ostStatus <= lastStatus
                warning('You are trying to access a formant perturbation line that does not exist, but should. Please check your PCF file.')
                return
            elseif strcmp('space', timeSpace) && ostStatus > lastStatus
                warning('You are trying to get the perturbation for an OST status that does not exist. Stopping script.')
                return
            else 
                warning('There is no perturbation line that is triggered by this OST status. Stopping script.')
                return
            end
        end
    end

end

%% Retrieving parameters

switch timeSpace
    case 'time'
        if length(components) == 5
            % If specified via tBegin, only 5 components so the indices will be different
            % set up structure with the different component indices
            paramsList = {'tBegin', 'rate1', 'dur1', 'durHold', 'rate2'}; 
            paramIx.tBegin = 1;
            paramIx.rate1 = 2;
            paramIx.dur1 = 3;
            paramIx.durHold = 4;
            paramIx.rate2 = 5;
            
            
        elseif length(components) == 6
            % OST status-headed lines have 6 components
            % set up structure with the different component indices
            if ischar(ostStatus)
                fprintf('Six components found. Interpreting ostStatus as an ordinal number, not the ostStatus number!\n') 
            end
            paramsList = {'ostStat_initial', 'tBegin', 'rate1', 'dur1', 'durHold', 'rate2'}; 
            paramIx.ostStat_initial = 1;
            paramIx.tBegin = 2;
            paramIx.rate1 = 3;
            paramIx.dur1 = 4;
            paramIx.durHold = 5;
            paramIx.rate2 = 6;     
            
        else
            warning('Something has gone horribly wrong; incorrect number of PCF line components. Stopping script')
            return
        end
            
    case 'space'        
        % set up structure with the different component indices
        paramsList = {'stat', 'pitchShift', 'gainShift', 'fmtPertAmp', 'fmtPertPhi'}; 
        paramIx.stat = 1;
        paramIx.pitchShift = 2;
        paramIx.gainShift = 3;
        paramIx.fmtPertAmp = 4;
        paramIx.fmtPertPhi = 5;       
end


if isempty(varargin)
    params = input('Which param value(s) would you like to retrieve? Type HELP for a full list: ', 's');
    if strcmpi(params, 'help')
        while strcmpi(params, 'help')
            proseParamList = [sprintf('%s, ', paramsList{1:end}) sprintf('or ALL if you would like to get all.\n')]; 
            fprintf('Possible parameters: %s\n', proseParamList)
            pause(1)
            params = input('Which param value(s) would you like to retrieve? Type HELP for a full list: ', 's');
            
        end
    end
    params = strsplit(params,','); 
elseif iscell(varargin)
    if iscell(varargin{1})
        params = varargin{1}; 
        % In case someone put it in as {'rate1'}, for example
    else 
        params = varargin; 
    end
end

if strcmp(params{1},'all')
    params = paramsList; 
end

%% Make output arg

for i = 1:length(params)
    paramToGet = params{i}; 
    if ~isfield(paramIx, paramToGet)
        warning('You tried to retrieve param %s but that does not exist for the %s type of perturbation.\n', upper(paramToGet), upper(timeSpace)); 
        return
    end
    varargout{i} = str2double(components{paramIx.(paramToGet)}); 
end
        
end