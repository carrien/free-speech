function varargout = calc_newAudapterData(sigIn,params,audFileLoc,audFileName,outputColumns)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function calculates a new data structure based on given pcf/ost files. Returns a specified column (e.g., signalOut,
% ost_stat) 
%
% Inputs: 
% - sigIn is the cell array of data you want to use as the signal in (can originally be a signalOut or signalIn or whatever)
%
% - params is the audapter parameters. Comes from data. Is a single struct---might change this later for things that change
% by trial? 
%
% - audFileLoc is the folder where the OST file is kept. 
% --- If anything other than experiment_helpers, will assume that audFileLoc is appended to current-studies. e.g. 'timeAdapt'
%
% - audFileName is the name of the tracking files you're using. ONLY works with working copies. 
% --- e.g. 'sapper' would point to sapperWorking.ost, 'measureFormants' to measureFormantsWorking.ost
%
% - outputColumn is the new calculated column you would like to receive back. 'ost_stat' 'signalOut' (probably the only ones
% you care about) 
% 
% This is called by audapter_viewer (currently exclusively, as of 10/31/2020) 
% 
% RK 1/24/2020
% restructuring edit: changed var data to var sigIn, deleted signal2use 2020/02/17
% edit for flexibility across experiment: exptName -> audFileLoc, audFileName -> audFileLoc. Parallels other changes to
% incorporate experiment_helpers/measureFormantsWorking.ost/pcf as the default tracking files. RPK 2020/10/31
% 
% RK 2/12/2021 this should probably be edited so you can get more than a single column, but less than the whole thing

dbstop if error

%% Defaults
if nargin < 1 || isempty(sigIn)
    load('data.mat')
    sigIn = {data.signalIn}; 
    warning('Using available data file')
end
if nargin < 2 || isempty(params)
    params = getAudapterDefaultParams('female'); % get default params
end
if nargin < 3 || isempty(audFileLoc), audFileLoc = 'experiment_helpers'; end
if nargin < 4 || isempty(audFileName), audFileName = 'measureFormants'; end 
if nargin < 5 || isempty(outputColumns), outputColumns = 'full'; warning('SMNG:calc_newAudapterData:fullReturn', 'Returning default of full data structure'); end

% Compatibility for multiple column extraction 
if ischar(outputColumns), outputColumns = {outputColumns}; end

if strcmp(audFileName, 'measureFormants') && ~strcmp(audFileLoc, 'experiment_helpers')
    warning('Using measureFormants OST from experiment_helpers instead of from folder %s. Should not use a measureFormants OST that is not the default.', audFileLoc)
end

%% Set up OST files

% Get the name of the OST, take out any .ost extensions if they exist
if strcmp(audFileLoc, 'experiment_helpers') || strcmp(audFileName, 'measureFormants')
    trackingPath = fullfile(get_gitPath('free-speech'), 'experiment_helpers'); 
elseif isfolder(audFileLoc)
    if contains(audFileLoc,'/') || contains(audFileLoc,'\')
        trackingPath = audFileLoc;
    else
        trackingPath = fullfile(get_gitPath('current-studies'), audFileLoc);
    end
else
    trackingPath = fullfile(get_gitPath('current-studies'), audFileLoc); 
end

pcfFN = fullfile(trackingPath,[audFileName 'Working.pcf']); 
ostFN = fullfile(trackingPath,[audFileName 'Working.ost']);

if ~isfile(pcfFN)
    refreshWorkingCopy(trackingPath, audFileName, 'pcf')
end
if ~isfile(ostFN)
    refreshWorkingCopy(trackingPath, audFileName, 'ost')
end

%% Params setup
        
% Run demo Audapter to get new OST lines
% params = data.params; 
% Compatibility for renamed parameters
if ~isfield(params,'bShift')
    params.bShift = 0;
end

if ~isfield(params, 'dScale') || isempty(params.dScale), params.dScale = params.scale ; end
if ~isfield(params, 'preempFact') || isempty(params.preempFact), params.preempFact = params.preemp ; end
if ~isfield(params, 'rmsThresh') || isempty(params.rmsThresh), params.rmsThresh = params.rmsThr ; end
if ~isfield(params, 'rmsRatioThresh') || isempty(params.rmsRatioThresh), params.rmsRatioThresh = params.rmsRatio ; end
if ~isfield(params, 'rmsForgFact') || isempty(params.rmsForgFact), params.rmsForgFact = params.rmsFF ; end
if ~isfield(params, 'dFmtsForgFact') || isempty(params.dFmtsForgFact), params.dFmtsForgFact = params.dFmtsFF ; end
if ~isfield(params, 'fb4gain') || isempty(params.fb4gain), params.fb4gain = params.fb4GainDB ; end
if ~isfield(params, 'gainAdapt') || isempty(params.gainAdapt), params.gainAdapt = params.bGainAdapt ; end
if ~isfield(params,'rmsFF_fb') || isempty(params.rmsFF_fb)
    params.rmsFF_fb = [0.85, 0.85, 0, 0];
end % Not sure why this isn't already in there? 


%% Actual calculation
% Set up Audapter
Audapter('ost',ostFN,0); 
Audapter('pcf',pcfFN,0);

% Run recalculation
for n = 1:length(sigIn)
    sig{n} = resample(sigIn{n}, params.downFact, 1);
%     if strcmp(signal2use,'calcSignalOut') && (~isfield(data(n),'calcSignalOut') || isempty(data(n).calcSignalOut))
%         sig{n} = resample(data(n).signalOut, params.downFact, 1); % failsafe for if there's no calcSignalOut for a trial but you tried to use it 
%         warning('No calcSignalOut for line %d of data. Using signalOut instead.',n)
%     else
%         sig{n} = resample(data(n).(signal2use), params.downFact, 1);
%     end
%     sig{n} = sigIn{n}; 
    sigFrame{n} = makecell(sig{n}, params.frameLen * params.downFact); %  * params.downFact
end

AudapterIO('init', params);
                     
for n = 1 : length(sig)
    Audapter('reset');   
    for m = 1:length(sigFrame{n})
        Audapter('runFrame', sigFrame{1,n}{1,m})
    end
    recalcData(n) = AudapterIO('getData');  
end

% Find things that are probably spurious events and set them to 0 
for n = 1:length(sig)
    lowInIx = find(abs([recalcData(n).signalIn]) < 0.00001); 
    lowOutIx = find(abs([recalcData(n).signalOut]) < 0.00001); 
    recalcData(n).signalIn(lowInIx) = 0; 
    recalcData(n).signalOut(lowOutIx) = 0; 
end

if strcmp(outputColumns,'full')
    varargout{1} = recalcData; 
else
    if length(sigIn) == 1
        for o = 1:length(outputColumns)
            varargout{o} = recalcData.(outputColumns{o}); 
        end
    else
        for o = 1:length(outputColumns)
            varargout{o} = {recalcData.(outputColumns{o})}; 
        end
    end
end

end