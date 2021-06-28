function [varargout] = get_ost(audFileDir, audFileName, eventNum, masterWorking)
% CWN
% This program can:
% 1.) retrieve info on a specified line in a specified OST file, and
% 2.) on-the-fly edit a single line in an OST file
%
% Input arguments:
% 1.) audFileLoc (formerly exptName): is the folder where the OST file is kept. 
% --- If anything other than experiment_helpers, will assume that audFileLoc is appended to current-studies. e.g. 'timeAdapt'
% --- defaults to 'experiment_helpers'
% 
% 2.) audFileName (formerly word): the name of the OST file. 
% --- defaults to 'measureFormants'
%
% 3.) eventNum: The OST event to be edited. 
% --- If you input a number like 2, you will get back just the OST info LEADING UP TO that status
% --- If you use option 'list', you will get a list of all the OSTs (ignoring 0), e.g. {'2'} {'4'} {'6'}
% --- If you use option 'full', you will get the ENTIRE OST file information, in the same format as if you just get_ost for
% all the OST statuses (i.e., you don't get LINES of OST; you get the heuristic and params that lead to an OST status) 
% --- Defaults to 'full'
% 
% ******* Note that the numeric value is not the LINE that will be retrieved, due to the structure of OST files.  The line 
% that will be retrieved is the one before the line that starts with eventNum. e.g. if eventNum = 6, you will get the
% heuristic and params from the line in the OST file that starts with 4 (or whatever the preceding status is), e.g.: 
% 
% 4 INTENSITY_RATIO_RISE 0.2 0.002 {} <--- this is the line that will be pulled/edited (the parameters that lead to 6)
% 6 INTENSITY_RISE_HOLD_POS_SLOPE 0.020 0.010 {} <--- this is the line that has your trigger status 
% 
% 4.) masterWorking: which version of the file you want to pull from. 
% --- 'master' to get the info from the master file. 
% --- 'working' to get info from the working file. 
% --- If unspecified, then defaults to working. 
%
% Last edit RPK 2019/11/21 split from timeAdapt_ostEdit into get/set. Added capability to get all OST statuses.
% RPK 2019/11/25 get from master (utility for refreshing single line) 
% RPK 2020/10/31 changed exptName -> audFileLoc and word -> audFileName. Made defaults for new experiment_helpers location
% and measureFormants. 
% RPK 2021/5/24 added functionality to get back third argument
% RPK 2021/06/24 added 'full' option to get the entire OST info for easy access/storage in data.subjOstParams

dbstop if error

%% Set defaults 

if nargin < 1 || isempty(audFileDir), audFileDir = 'experiment_helpers'; end
if nargin < 2 || isempty(audFileName), audFileName = 'measureFormants'; end

if strcmp(audFileName, 'measureFormants') && ~strcmp(audFileDir, 'experiment_helpers')
    warning('Using measureFormants OST from experiment_helpers instead of from folder %s. Should not use a measureFormants OST that is not the default.', audFileDir)
end

if nargin < 3 || isempty(eventNum)
    eventNum = 'full'; % Assume you want the whole banana if you don't specify
end
if nargin < 4 || isempty(masterWorking), masterWorking = 'working'; end
if isnumeric(eventNum); eventNum = num2str(eventNum); end

%% Grab necessary info from OST file

if strcmp(audFileDir, 'experiment_helpers') || strcmp(audFileName, 'measureFormants')
    trackingPath = fullfile(get_gitPath, 'free-speech', 'experiment_helpers'); 
else
    trackingPath = fullfile(get_gitPath, 'current-studies', audFileDir); 
end

switch masterWorking
    case 'master' 
        ostFile = fullfile(trackingPath,[audFileName 'Master.ost']); % I'm lazy and don't feel like making the first letter be capital
    case 'working' 
        ostFile = fullfile(trackingPath,[audFileName 'Working.ost']);
end

% If a working copy doesn't exist, make one
if exist(ostFile,'file') ~= 2
    refreshWorkingCopy(audFileDir,audFileName,'ost');
end

% Open file
fid = fopen(ostFile,'r');

% Load file line by line into structure finfo
tline = fgetl(fid);
i = 1;
o = 1; 
finfo{i} = tline;
while ischar(tline)    
    i = i+1;
    tline = fgetl(fid);    
    if ~isnumeric(tline) && ~isempty(tline)
        finfo{i} = tline; 
        lineComponents = strsplit(tline,' '); 
        if ~isnan(str2double(lineComponents(1))) && str2double(lineComponents(1)) ~= 0 
            osts(o) = lineComponents(1); 
            o = o+1;             
        end
        if strcmp(lineComponents(1), eventNum) 
            lineloc = i - 1; % Save line number before the one that starts with eventNum
        elseif strcmp(lineComponents(1), '0')
            fullOstStartLine = i + 1; % Get the line where you get the first OST stuff going (not the 0th line) 
        elseif strcmp(lineComponents(2), 'OST_END')
            fullOstEndLine = i; % Get the last informative OST line, which obligatorily has OST_END as the heuristic
        end
    end  
end

% Close file
fclose(fid);

%% 
% Get output args

if strcmp(eventNum,'list')
    ostList = osts; 
    varargout{1} = ostList; 
elseif strcmp(eventNum, 'full') % This provides a more efficient way of grabbing the entire OST file 
    linelist = fullOstStartLine:fullOstEndLine; 
    for i = 1:length(linelist)
        finfoline = linelist(i) - 1; % Because you need to get the info from the preceding line
        components = strsplit(finfo{finfoline}, ' '); 
        ostStatus = str2double(osts{i}); % This just happens to match how I spit out subjOstParams, using a number, not the string '2'  
        heurName = components{2}; 
        heuristicParam1 = str2double(components{3});
        heuristicParam2 = str2double(components{4});
        heuristicParam3 = str2double(components{5}); % Adding for third parameter functionality. Gives NaN if empty ('{}')
        fullInfo{i} = {ostStatus heurName heuristicParam1 heuristicParam2 heuristicParam3}; 
    end
    varargout{1} = fullInfo; 
else 
    % Find the right line and separate into components
    components = strsplit(finfo{lineloc}, ' ');
    heurName = components{2}; 
    heuristicParam1 = str2double(components{3});
    heuristicParam2 = str2double(components{4});
    heuristicParam3 = str2double(components{5}); % Adding for third parameter functionality. Gives NaN if empty ('{}')
    
    varargout{1} = heurName; 
    varargout{2} = heuristicParam1; 
    varargout{3} = heuristicParam2; 
    varargout{4} = heuristicParam3; 
end
    

end