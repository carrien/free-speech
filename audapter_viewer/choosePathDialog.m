function pathChoice = choosePathDialog(possiblePaths, bServer)
% Function to create a dialog verifying where you would like to save the data/expt output from audapter_viewer
% 
% Dialog provides dropdown with path options (specified as a cell array in possiblePaths), plus "choose another folder"
% option. If you choose another path, then it opens a uigetdir dialog so you can select a path. 
% 
% Basic use of this is server version vs. experiment computer version of paths. 
% 
% Inputs: 
% 1. possiblePaths: cell array of possible paths, e.g.
% {'\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\timeAdapt\sp001\capper'
% 'C:\Users\Public\Documents\experiments\timeAdapt\sp001\capper'}
% --- defaults to current working directory 
% 2. bServer, if that folder exists on the server (if you are deciding between expt and server version, sometimes it might
% not exist) 
% --- defaults to 0 
% 
% INitiated RPK 2021/06/23

dbstop if error

%% Defaults
if nargin < 1 || isempty(possiblePaths)
    possiblePaths = {pwd}; 
end

pathChoice = 0; % default is 0, functioning essentially as cancel 
% If you have only one path for some reason, make sure it is a cell 
if ~iscell(possiblePaths)
    possiblePaths = {possiblePaths}; 
end

if nargin < 2 || isempty(bServer) || ~bServer
    % If you don't pass in bServer, assume that the folder doesn't exist. Look for the non-server folder
    defaultPopup = find(~contains(possiblePaths, '\\wcs-cifs.waisman.wisc.edu\')); 
else
    % If the server folder is specified to exist, make that the default 
    defaultPopup = find(contains(possiblePaths, '\\wcs-cifs.waisman.wisc.edu\'));  
end

% If there is no server path or if there is more than one server path 
if length(defaultPopup) > 1
    defaultPopup = min(defaultPopup); 
elseif isempty(defaultPopup)
    defaultPopup = 1; 
end


% Create dialog box container
dlg = dialog('Name', 'Verify save location', ...
    'Units', 'Normalized', 'Position',[0.3 0.4 0.4 0.2]);

% Text telling you what you're doing
txt = uicontrol('Parent', dlg, 'Style', 'text', ...
    'Units', 'Normalized', 'Position', [0.1 0.7 0.8 0.2], 'FontSize', 10,...
    'String', 'Please verify the location where you would like to save the data and expt structure:'); 

% Drop-down menu with possible paths in it
popup = uicontrol('Parent',dlg,...
           'Style','popupmenu',...
            'Units', 'Normalized', 'Position', [0.1 0.5 0.8 0.1], ...
           'String',[possiblePaths 'Choose another folder...'], 'FontSize', 10, ...
           'Value', defaultPopup, ...
           'Callback', @popup_callback);

% Okay button. deletes dialog box
hbutton.okay = uicontrol('Parent',dlg,...
            'Units', 'Normalized', 'Position', [0.3 0.2 0.15 0.1], ...
           'String','OK',...
           'Callback',@makeSelection);

% Cancel button. Returns 0 
hbutton.cancel = uicontrol('Parent',dlg,...
    'Units', 'Normalized', 'Position', [0.55 0.2 0.15 0.1], ...
    'String','Cancel',...
    'Callback',@cancel);

% Wait for dlg to close before running to completion
uiwait(dlg);
if strcmp(pathChoice, 'Choose another folder...')
    pathChoice = uigetdir; 
end

function cancel(hObject,event)
    pathChoice = 0; 
    delete(gcf); 
    return; 
end   
        
function popup_callback(popup,event)
    idx = popup.Value;
    popup_items = popup.String;
    pathChoice = char(popup_items(idx,:));
end

function makeSelection(hObject, event)
    idx = popup.Value;
    popup_items = popup.String;
    pathChoice = char(popup_items(idx,:));
    delete(gcf);
end
end