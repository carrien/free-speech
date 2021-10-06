function [] = set_ost(audFileDir, audFileName, eventNum, varargin)
% CWN / RPK
% This program can on-the-fly edit a single line in an OST file
%
% Input arguments:
% 1.) audFileLoc (formerly exptName): is the folder where the OST file is kept. 
% --- If anything other than experiment_helpers, will assume that audFileLoc is appended to current-studies. e.g. 'timeAdapt'
% --- defaults to 'experiment_helpers'
% 2.) audFileName (formerly word): the name of the OST file. 
% --- defaults to 'measureFormants'
% 3.) eventNum: The OST event to be edited.  Note that this is not the LINE that will be edited, due to the structure of OST
% files.  The line that will be edited is the one before the line that starts with eventNum.  e.g. if eventNum = 6, 
% 
% 4 INTENSITY_RATIO_RISE 0.2 0.002 {} <--- this is the line that will be pulled/edited (the parameters that lead to 6)
% 6 INTENSITY_RISE_HOLD_POS_SLOPE 0.020 0.010 {} <--- this is the line that has your trigger status 
%
% 4.) varargin: The value(s) to insert in an OST file. Receives up to 3 arguments: 
% --- varargin{1}: if you want to change the actual HEURISTIC
% --- varargin{2}: if you want to change the first parameter
% --- varargin{3}: if you want to change the second parameter 
% --- varargin{4}: if you want to change the third parameter (not all heuristics take this parameter) 
% For any values you do not want to change, use some version of empty: {}, [], etc. 
% (former versions allowed -1; this is not good because stretch/span I believe uses negative numbers, possibly including -1) 
% 
% OR 
% varargin = 'reset' if you want to simply reset a single line back to master file values
%
% Last edit: RPK 2019/11/21 (split get/set. Added capability to change heuristic)
% RPK 2019/11/25 added ability to set single line back to master params
% RPK 2020/10/31 changed exptName -> audFileLoc and word -> audFileName. Made defaults for new experiment_helpers location
% and measureFormants. 
% RPK 5/24/2021 added capabilities for third parameter

dbstop if error

%% Defaults

if nargin < 1 || isempty(audFileDir), audFileDir = 'experiment_helpers'; end
if nargin < 2 || isempty(audFileName), audFileName = 'measureFormants'; end

if strcmp(audFileName, 'measureFormants') && ~strcmp(audFileDir, 'experiment_helpers')
    warning('Using measureFormants OST from experiment_helpers instead of from folder %s. Should not use a measureFormants OST that is not the default.', audFileDir)
end

%%

% Convert eventNum to string
if nargin < 3 || isempty(eventNum)
    eventNum = input('What event number would you like to edit? '); 
end
if isnumeric(eventNum); eventNum = num2str(eventNum); end

% RPK 5/24/2021: this is redone to make more elegant from previously. Now you can just leave arguments empty if you don't
% want to change them
if length(varargin) < 1 
   editParam = askNChoiceQuestion('What are you trying to edit?', {'heuristic' 'param1' 'param2' 'param3'}); 
   %input('What are you trying to edit? (heuristic, param1, param2): ', 's');
%    while ~any(strcmp(editParam,{'heuristic','param1','param2'}))
%        editParam = input('Invalid choice. Please enter heuristic/param1/param2: ','s');
%    end
   params = strsplit(editParam, ','); 
   if any(strcmp(params,'heuristic'))
       newHeurValue = input('What would you like as the new heuristic? ', 's'); 
   else 
       newHeurValue = []; 
   end
   if any(strcmp(params,'param1'))
       newParam1Value = input('What value would you like to insert as parameter 1? '); 
   else 
       newParam1Value = []; 
   end
   if any(strcmp(params,'param2'))
       newParam2Value = input('What value would you like to insert as parameter 2? '); 
   else 
       newParam2Value = []; 
   end
   if any(strcmp(params,'param3'))
       newParam3Value = input('What value would you like to insert as parameter 3? '); 
   else 
       newParam3Value = []; 
   end
elseif strcmp(varargin{1},'reset')
    [newHeurValue, newParam1Value, newParam2Value, newParam3Value] = get_ost(audFileDir, audFileName, eventNum, 'master'); 
end

% Initiate arguments as empty
newHeurValue = {}; 
newParam1Value = {}; 
newParam2Value = {}; 
newParam3Value = {}; 

% Assign new values if their positions are specified
try newHeurValue = varargin{1}; catch; end
try newParam1Value = varargin{2}; catch; end
try newParam2Value = varargin{3}; catch; end
try newParam3Value = varargin{4}; catch; end



%% Grab necessary info from OST file

% CWN 9/11/19 Note that this function only edits the Working copy of an OST.
% Call refreshWorkingCopy from the source function if needed before calling
% this function.
% Get the name of the OST, take out any .ost extensions if they exist
if strcmp(audFileDir, 'experiment_helpers') || strcmp(audFileName, 'measureFormants')
    trackingPath = fullfile(get_gitPath, 'free-speech', 'experiment_helpers'); 
elseif isfolder(audFileDir) %if audFileDir was provided as full path
    if contains(audFileDir,'/') || contains(audFileDir,'\')
        trackingPath = audFileDir;
    else
        trackingPath = fullfile(get_gitPath, 'current-studies', audFileDir);
    end
else
    trackingPath = fullfile(get_gitPath, 'current-studies', audFileDir); 
end

ostFile = fullfile(trackingPath,[audFileName 'Working.ost']);

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
    finfo{i} = tline; 
    if ~isnumeric(tline) && ~isempty(tline)
        lineComponents = strsplit(tline,' '); % Need to do this so that you can compare double-digit OST statuses
        if strcmp(lineComponents(1), eventNum) 
            lineloc = i - 1; % Save line number before the one that starts with eventNum
        end
    end    
end

% Close file
fclose(fid);

%% 
% Separate line into its parameters
components = strsplit(finfo{lineloc}, ' ');

if ~isempty(newHeurValue)
    components{2} = upper(newHeurValue); 
end
if ~isempty(newParam1Value) 
    components{3} = sprintf('%.3f',newParam1Value);
end
if ~isempty(newParam2Value)
    components{4} = sprintf('%.3f',newParam2Value);
end
if ~isempty(newParam3Value)
    if isnan(newParam3Value)
        components{5} = '{}'; 
    else
        components{5} = sprintf('%.3f',newParam3Value);
    end
end
    
    newLine = strjoin(components,' ');
    finfo{lineloc} = newLine;
    
    % overwrite file with updated info on lineloc
    fid = fopen(ostFile,'w');
    for i = 1:numel(finfo)
        if finfo{i+1} == -1
            fprintf(fid, '%s', finfo{i});
            break
        else
            fprintf(fid, '%s\n', finfo{i});
        end
    end
    fclose(fid);
    
end