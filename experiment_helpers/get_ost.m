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
% 2.) audFileName (formerly word): the name of the OST file. 
% --- defaults to 'measureFormants'
% 3.) eventNum: The OST event to be edited. Either a number or 'list', in which case you will get all the OSTs (ignoring 0) 
% *** Note that the numeric value is not the LINE that will be retrieved, due to the structure of OST
% files.  The line that will be retrieved is the one before the line that starts with eventNum.  e.g. if eventNum = 6, 
% 4.) varargin: optional 'master' to get the info from the master file. If empty, then is set as working. 
% 
% 4 INTENSITY_RATIO_RISE 0.2 0.002 {} <--- this is the line that will be pulled/edited (the parameters that lead to 6)
% 6 INTENSITY_RISE_HOLD_POS_SLOPE 0.020 0.010 {} <--- this is the line that has your trigger status 
%
% Last edit RPK 2019/11/21 split from timeAdapt_ostEdit into get/set. Added capability to get all OST statuses.
% RPK 2019/11/25 get from master (utility for refreshing single line) 
% RPK 2020/10/31 changed exptName -> audFileLoc and word -> audFileName. Made defaults for new experiment_helpers location
% and measureFormants. 
% RPK 2021/5/24 added functionality to get back third argument

dbstop if error

%% Set defaults 

if nargin < 1 || isempty(audFileDir), audFileDir = 'experiment_helpers'; end
if nargin < 2 || isempty(audFileName), audFileName = 'measureFormants'; end

if strcmp(audFileName, 'measureFormants') && ~strcmp(audFileDir, 'experiment_helpers')
    warning('Using measureFormants OST from experiment_helpers instead of from folder %s. Should not use a measureFormants OST that is not the default.', audFileDir)
end

if nargin < 3 || isempty(eventNum)
    eventNum = input('What event number would you like to retrieve? (Number, or ''list''): ', 's'); 
end
if nargin < 4 || isempty(masterWorking), masterWorking = 'working'; end
if isnumeric(eventNum); eventNum = num2str(eventNum); end

%% Grab necessary info from OST file

% CWN 9/11/19 Note that this function only edits the Working copy of an OST.
% Call refreshWorkingCopy from the source function if needed before calling
% this function.
if strcmp(audFileDir, 'experiment_helpers') || strcmp(audFileName, 'measureFormants')
    trackingPath = fullfile(get_gitPath, 'free-speech', 'experiment_helpers'); 
else
    trackingPath = fullfile(get_gitPath, 'current-studies', audFileDir); 
end

ostFile = fullfile(trackingPath,[audFileName 'Working.ost']);

% If a working copy doesn't exist, make one
if exist(ostFile,'file') ~= 2
    refreshWorkingCopy(audFileDir,audFileName,'ost');
end


% If a working copy doesn't exist, make one
if exist(ostFile,'file') ~= 2
    refreshWorkingCopy(audFileDir, audFileName, 'ost');
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