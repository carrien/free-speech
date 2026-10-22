function [dataVals] = gen_timingDataVals(dataPath,buffertype,bSave,varargin) %textField,seg_list)
%
% Largely copied from gen_dataVals_tramTransfer. This is the generic function that will simply get the start times and
% duration of segments labeled by user events. It assumes that all labeled user events are fair game. This works best with
% MFA-aligned data. 
% 
% INPUTS
% 
%       dataPath                the folder where the trial and trials_signalOut folders are that have 1.mat, etc. Defaults to
%                               pwd. Also needs an expt.mat
% 
%       buffertype              signalIn or signalOut. Defaults to signalIn
% 
%       bSave                   a check for whether or not you will save (overwrite!). If not specified, will perform a check
%                               for the existence of a dataVals file; if one already exists then it will ask you want to
%                               overwrite. 
% 
%   varargin: (must be in this order!!) 
% 
%       textField               the field in expt that has the text that was used for labeling. Defaults to stimulusText. 
% 
%       seg_list                the list of segments that you actually want to get information for. Defaults to all. Specify
%                               as a cell array. (Argument handling will also take a single segment as a string) 
% 
% OUTPUTS
% 
%       dataVals                either dataVals_signalIn.mat or dataVals_signalOut.mat is saved. Fields: 
%                                   - segDur: all segments from seg_list will have a field called segDur (e.g., eDur, cDur).
%                                   This is the duration of the interval between the user event labeled as such and the next
%                                   user event 
%                                   - segStart_time: all segments from seg_list will have a field called segStart_time (e.g.,
%                                   eStart_time, cStart_time). This is the time of the user event with that label 
%                                   - trial: the trial number
%                                   - token: the repetition for that specific word/phrase 
%                                   - wordList: the text of what was said (from expt.listWords) 
%                                   - condList: the condition for that trial (from expt.listConds)
%                                   - word: the number of the word that was said (from expt.allWords)
%                                   - cond: the number of the condition that was used for that trial (from expt.allConds)
%                                   - bPerturb: whether or not there was a perturbation on that trial (taken from
%                                   expt.pertMag)
%                                   - bExcl: if the trial has been marked as bad
%                                   - bFishy: if the trial has the wrong number of (nonempty) events
%                                   - bFlip: if the order of the user events is off (according to arpabet string) 
% 
% 
%  
% Initiated RK 2025/06/26 

dbstop if error 

%%
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(buffertype), buffertype = 'signalIn'; end
% set output files
if strcmp(buffertype, 'signalIn')
    trialDir = 'trials';
else
    trialDir = 'trials_signalOut'; 
end
savefile = fullfile(dataPath,['dataVals_' buffertype '.mat']);

if nargin < 3 || isempty(bSave), bSave = savecheck(savefile); end

if ~bSave
    warning('Can''t save to expected location (%s). Ending script.', savefile);
    return; 
end

% Set up varargin for textField (fourth input) 
if nargin >= 4
    textField = varargin{1}; 
else
    textField = []; 
end
if isempty(textField), textField = 'stimulusText'; end
if iscell(textField)
    textField = textField{1}; % if it comes in as part of varargin, then it'll come in as a cell 
end

% Set up varargin for seg_list (fifth input)
if nargin >= 5
    seg_list = varargin{2}; 
else
    seg_list = []; 
end
if isempty(seg_list), seg_list = {'all'}; end
if ischar(seg_list), seg_list = {seg_list}; end % convert to cell if necessary 
if iscell(seg_list{1}), seg_list = seg_list{1}; end % if it comes in as part of varargin i think it'll be a cell within a cell 

%%
% load expt files
load(fullfile(dataPath,'expt.mat'), 'expt');
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
trialPath = fullfile(dataPath,trialDir); % e.g. trials; trials_default
[sortedTrialnums,sortedFilenames] = get_sortedTrials(trialPath); % these should be the same for both in/out so only need to define once
dataVals = struct([]);

%% This is for finding the correct tokens if there is more than one stimulus in a study 
for i = 1:length(expt.words)
    word = expt.words{i}; 
    ix.(word) = find(expt.allWords == i); 
end

%% Get all unique arpabet strings for the stimuli in the study 
exptPhrases = []; 
for s = 1:length(expt.(textField))
    singlePhrase = []; 
    stimulusText = expt.(textField){s}; 
    splitStim = split(stimulusText, ' '); % Split by spaces into cells so you can string together the whole tihng
    
    % go through each word and get the arpabet for it 
    for p = 1:length(splitStim)
        stimPart = splitStim{p}; 
        arpaStimPart = word2arpabet(stimPart); 
        if length(arpaStimPart) > 1
            questionText = warning('There are multiple versions of this word ("%s"): ', stimPart); 
            for a = 1:length(arpaStimPart)
                versionText = [fprintf('Version %d: ', a) fprintf('%s ', arpaStimPart{a}{1:end}) fprintf('\n')]; 
            end
            whichOne = askNChoiceQuestion('Which one would you like to use?', [1:length(arpaStimPart)]); 
        else
            whichOne = 1; 
        end
        
        arpaStimPart = arpaStimPart{whichOne}; 

        % Strip out numbers that mark stress (this is what UEVs do from MFA) 
        for q = 1:length(arpaStimPart)
            arpa = arpaStimPart{q};
            arpa(regexp(arpa,'[0,1,2]'))=[];
            arpaStimPart{q} = char(arpa);
        end

        singlePhrase = [singlePhrase arpaStimPart]; 
    end

    exptPhrases{s} = singlePhrase;
end

% exptPhrases has all of the unique arpabet sequences for the stimuli used in the experiment. They are in the order of the
% stimuli, e.g. words or stimulusText. This will be used to index in 

%% Extract data from each trial

% e = 1; % error trial counter
% errorTrials = []; 
fprintf('Generating dataVals for %s... ', buffertype)
bSkip = 0; 
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    print_locationInLoop(trialnum, 25, i); 
    n_events = 0; 

    trialStimulus = exptPhrases{expt.(['all' upper(textField(1)) textField(2:end)])(trialnum)}; 
    max_events = length(trialStimulus); % This is the number of LABELED events
    if strcmp(seg_list{1}, 'all')
        segs2evaluate = trialStimulus; 
    else
        segs2evaluate = seg_list; 
    end
    
    % Load in the trial.mat file 
    if exist(fullfile(trialPath, filename), 'file')
        load(fullfile(trialPath,filename)); 
    
        % get user-created events
        if exist('trialparams','var') ...
                && isfield(trialparams,'event_params') ...
                && ~isempty(trialparams.event_params)
            user_event_times = trialparams.event_params.user_event_times;
            user_event_names = trialparams.event_params.user_event_names;

            % Sort user events chronologically for accurate comparison
            [chron_user_event_times, timesortix] = sort(user_event_times); 
            chron_user_event_names = user_event_names(timesortix); 
            
            % Check to make sure that the very last event is empty---otherwise you're gonna error out when getting a duration (and
            % something probably went wrong) 
            if ~isempty(chron_user_event_names{end}) 
                dataVals(i).bFishy = 1; 
                bSkip = 1; 
            else
                dataVals(i).bFishy = 0; 
                bSkip = 0; 
            end
        else
            user_event_times = [];
            user_event_names = {}; 
            warning('No events for trial %d\n',trialnum); 
            bSkip = 1;
        end
        
    else
        % If there's no file then obviously skipping 
        bSkip = 1; 
    end
    
    % Get general trial information, regardless of whether you can get actual duration info from the trial 
    dataVals(i).wordList = expt.listWords(trialnum); 
    dataVals(i).condList = expt.listConds(trialnum);
    dataVals(i).word = expt.allWords(trialnum); % this is for grouping purposes in check_timingDataVals
    dataVals(i).cond = expt.allConds(trialnum); 
    dataVals(i).trial = trialnum; % Trial number
    dataVals(i).token = find(trialnum == ix.(expt.listWords{trialnum})); % repetition of that specific word 
    if isfield(expt, 'pertMag')
        if expt.pertMag(trialnum) > 0
            dataVals(i).bPerturb = 1;
        else
            dataVals(i).bPerturb = 0; 
        end
    else
        % Not all experiments have this 
        dataVals(i).bPerturb = 0; 
    end
    
    % If you've determined that you DO ACTUALLY HAVE EVENTS then you can start getting the actual data 
    if trialparams.event_params.is_good_trial && ~bSkip       

        % Do some checks about the integrity of each trial 
        nLabeledUevs = sum(~cellfun(@isempty, user_event_names)); 
        if nLabeledUevs ~= max_events
            dataVals(i).bFishy = 1; 
            dataVals(i).bFlip = 0; % can't check for flipping really because the trial is already messed up 
        else
            dataVals(i).bFishy = 0;
            [~, uevSortIx] = sort(chron_user_event_names(~cellfun(@isempty, chron_user_event_names))); 
            [~, phraseSortIx] = sort(trialStimulus); 
            % If, when you sort the events alphabetically, you don't do the same rearranging as the actual phrase order, 
            % then it's possible you flipped some events 
            if any(uevSortIx ~= phraseSortIx)
                dataVals(i).bFlip = 1; 
            else
                dataVals(i).bFlip = 0; 
            end
                
        end
        
        % Get the durations and start times of each segment 
        for s = 1:length(segs2evaluate)
            seg = lower(segs2evaluate{s}); 
            uevix = find(strcmpi(chron_user_event_names, seg)); % not case sensitive---can specify in lowercase though MFA gives in upper
            dataVals(i).([seg 'Dur']) = chron_user_event_times(uevix + 1) - user_event_times(uevix); 
            dataVals(i).([seg 'Start_time']) = chron_user_event_times(uevix); 
        end
            
%         
% 
%               
% 
%         if n_events > max_events
%             warning('%d events found in trial %d (expected %d)',n_events,trialnum,max_events);
%             fprintf('ignoring event %d\n',max_events+1:n_events)
%         elseif n_events < max_events
%             warning('Only %d events found in trial %d (expected %d)',n_events,trialnum,max_events);
%             fprintf('Check for empty values.\n')
%             errorTrials(e) = trialnum; 
%             e = e+1; 
%         end

    else
        % Other exclusions 
        dataVals(i).bFishy = 1; % basically just means that you don't have something here but you probably should 
        dataVals(i).bFlip = 0; % no events so nothing to flip 
        
        % bad and non-existent trials get all NaNs for the time values
        for s = 1:length(segs2evaluate)
            seg = lower(segs2evaluate{s}); 
            dataVals(i).([seg 'Dur']) = NaN; 
            dataVals(i).([seg 'Start_time']) = NaN;  
        end

    end
    
    % Now finally check for it being a bad trial 
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
end

%% Save the dataVals

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile);

end
