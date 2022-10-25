function [methodUsed] = set_subjOstParams_auto(expt, data, bRefresh, ostTrial)
% Wrapper function for set_subjOstParams, which chooses the most precise
% version of the ost parameters that exist, then sets the OST file to those
% parameters.
%
% If you need to precisely set your OST file to a particular configuration,
% ie, using expt/data or specifying a certain field, call set_subjOstParams
% directly.
%
% INPUT ARGS:
%   expt: The expt.mat file
%   data: The data.mat file
%   bRefresh: A binary switch. If none of expt.subjOstParams,
%     expt.calcSubjOstParams, data.subjOstParams, nor data.calcSubjOstParams
%     exist, AND if bRefresh is 1, then the OST working file will be
%     refreshed relative to the master. If all of the above but bRefresh is
%     0, then no changes will be made to the OST file.
%   ostTrial: The particular trial you want to use as the basis for OST
%     params. Only relevant when using the data struct. Defaults to 1.
%
% OUTPUT ARGS:
%   methodUsed: A string telling you which struct and field (if any) were
%     used when setting the OST file.
%
% 2021-08 CWN init.


%% input arg handling
if nargin < 1, expt = []; end
if nargin < 2, data = []; end
if nargin < 3 || isempty(bRefresh), bRefresh = 1; end

if isstruct(data), bData = 1; else, bData = 0; end
if isstruct(expt), bExpt = 1; else, bExpt = 0; end

if nargin < 4 || isempty(ostTrial)
    if bData
        % If OSTs were changed during experiment, the last trial would have
        % the most-recently-updated OST values
        ostTrial = length(data);
    else
        ostTrial = 1;
    end
end

%% Setup to determine how to call set_subjOstParams
% file directory
if isfield(expt, 'trackingFileDir')
    fileDir = expt.trackingFileDir;
elseif isfield(expt, 'trackingFileLoc')
    fileDir = expt.trackingFileLoc;
elseif isfield(expt, 'name') && strcmp(expt.name, 'timeAdapt')
    fileDir = expt.name;
else
    fileDir = 'experiment_helpers';
end

% file name
if isfield(expt, 'trackingFileName')
    if iscell(expt.trackingFileName) 
        if length(expt.trackingFileName) > 1
            % If you have more than one tracking file in an expt, then you'll have to figure out which one you're using
            % Get the word number that was used for ostTrial
            wordInTrial = expt.allWords(ostTrial); 
            % Use that number to get the corresponding OST filename
            fileName = expt.trackingFileName{wordInTrial};             
            fprintf('Setting OST based on file name ''%s'' and ostTrial = %d\n', fileName, ostTrial); 
        else
            fileName = expt.trackingFileName{1}; % This just translates it to a string 
        end
    else
        fileName = expt.trackingFileName; % This just translates it to a string 
    end
elseif isfield(expt, 'name') && strcmp(expt.name, 'timeAdapt')
    % timeAdapt is an experiment that did not have trackingFileName but still used different OST files for different
    % conditions
    fileName = expt.listWords{1};
else
    fileName = 'measureFormants';
end
    
%% actual calls to set_subjOstParams
if bData && isfield(data, 'calcSubjOstParams') && ~isempty(data(ostTrial).calcSubjOstParams)
    set_subjOstParams(fileDir, fileName, data(ostTrial), 'calc');
    methodUsed = 'data.calcSubjOstParams';
    
elseif bData && isfield(data, 'subjOstParams') && ~isempty(data(ostTrial).subjOstParams)
    set_subjOstParams(fileDir, fileName, data(ostTrial), 'orig');
    methodUsed = 'data.subjOstParams';
    
elseif bExpt && isfield(expt,'calcSubjOstParams') && ~isempty(expt.calcSubjOstParams)
    set_subjOstParams(fileDir, fileName, expt, 'calc');
    methodUsed = 'expt.calcSubjOstParams';
    
elseif bExpt && isfield(expt,'subjOstParams') && ~isempty(expt.subjOstParams)
    set_subjOstParams(fileDir, fileName, expt, 'orig');
    methodUsed = 'expt.subjOstParams';
    
elseif bRefresh % If you haven't stored ost params anywhere 
    refreshWorkingCopy(fileDir, fileName, 'ost'); 
    methodUsed = 'refreshWorkingCopy';
    
else
    methodUsed = 'none';
    
end


end %EOF