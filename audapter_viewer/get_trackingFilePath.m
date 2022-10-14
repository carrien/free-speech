function [trackingFilePath] = get_trackingFilePath(trackingFileFolder, trackingFileName)
% Function to replace identical lines of code in every function that looks for OST or PCF files 
% 
% Given a folder name and an (optional) file name, gets you the path to the folder that contains the tracking file of
% concern. These two arguments should be already supplied to whatever function is calling this function. 
% 
% INPUT ARGUMENTS
% 
%   trackingFileFolder              The folder that contains the tracking file. This can be in two different formats: 
%                                   --- full path, e.g. 'C:\Users\Public\Documents\software\cerebellar-battery\taimComp'
%                                   --- just the folder name, e.g. 'timeWrap'. If you specify this, the assumption is that it
%                                   is in current-studies. If you are using some other repo, such as cerebellar-battery, you
%                                   must provide the full path. 
%                                   --- EXCEPTION: if you provide experiment_helpers, it will get free-speech
% 
%                                   NOTE: If this is empty, it will assume experiment_helpers and thus free-speech (since the 
%                                   lab default is free-speech/experiment_helpers/measureFormants.....) 
% 
%   trackingFileName                The name of the tracking file (excluding any suffixes like Master.ost or Working.ost)
%                                   --- If this is empty, it will assume measureFormants from free-speech (this aligns with
%                                   expectations in other scripts) 
%                                   --- If this is measureFormants, it will force the output path to be experiment_helpers in
%                                   free-speech. There should be no other file called measureFormants that you're trying to 
%                                   work with! 
% 
% OUTPUTS 
% 
%   trackingFilePath                The fully specified path that contains the tracking file you are looking for. Does not
%                                   include the actual tracking file (this is done later in whatever function has called this
%                                   script) 
% 
% Initiated RPK October 2022 to stop from changing a million functions separately 
% 

dbstop if error

%% Defaults

if nargin < 2 || isempty(trackingFileName) 
    % Check if trackingFileFolder is either empty or experiment_helpers
    if nargin < 1 || isempty(trackingFileFolder) || strcmp(trackingFileFolder, 'experiment_helpers')
        % If so, then this can be measureFormants
        trackingFileName = 'measureFormants'; 
    else 
        % Otherwise, leave it blank so it doesn't trigger default behavior (this should basically never need to occur, but
        % just in case) 
        trackingFileName = []; 
    end
end

if nargin < 1 || isempty(trackingFileFolder), trackingFileFolder = 'experiment_helpers'; end


%% Get path to tracking file

if strcmp(trackingFileFolder, 'experiment_helpers') || strcmp(trackingFileName, 'measureFormants')
    % Default behavior
    trackingFilePath = fullfile(get_gitPath('free-speech'), 'experiment_helpers'); 
    
elseif contains(trackingFileFolder, '/') || contains(trackingFileFolder, '\') 
    % If you provided a full path 
    trackingFilePath = trackingFileFolder;

else
    % If you provided a folder name without the rest of the path, and it is not experiment_helpers, it is that experiment's
    % folder in current-studies
    trackingFilePath = fullfile(get_gitPath('current-studies'), trackingFileFolder); 
end

end