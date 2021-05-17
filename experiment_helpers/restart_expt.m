function expPath = restart_expt(expt)
%RESTART_EXPT  Restart experiment after a crash.

if nargin < 1, expt = []; end

if ~isfield(expt,'name'), expt.name = input('enter experiment name: ','s'); end
if ~isfield(expt,'snum'), expt.snum = get_snum; end

expFun = get_experiment_function(expt.name);

% find all temp trial dirs
subjPath = get_acoustSavePath(expt.name,expt.snum);
tempdirs = regexp(genpath(subjPath),'[^;]*temp_trials','match')';
if isempty(tempdirs)
    fprintf('No unfinished experiments to restart.\n')
    expPath = [];
    return;
end

% prompt for restart
for d = 1:length(tempdirs)
    %find last trial saved
    trialnums = get_sortedTrials(tempdirs{d});
    lastTrial = trialnums(end);
    
    %check to see if experiment completed. only prompt to rerun if
    %incomplete.
    dataPath = fileparts(strip(tempdirs{d},'right',filesep));
    load(fullfile(dataPath,'expt.mat'), 'expt') % get expt file 
    if lastTrial ~= expt.ntrials
        startName = regexp(dataPath,expt.snum);
        expName = dataPath(startName:end);
        q = sprintf('Restart experiment "%s" at trial %d? [y/n] ', expName, lastTrial+1);
        q = strrep(q,'\','\\'); %add extra \ to string to display correctly in "input" command
        response = input(q, 's');
        if strcmp(response,'y')
            % setup expt
            expt.startTrial = lastTrial+1;      % set starting trial
            expt.startBlock = ceil(expt.startTrial/expt.ntrials_per_block); % get starting block
            expt.isRestart = 1;
            expt.crashTrials = [expt.crashTrials expt.startTrial];
            save(fullfile(dataPath,'expt.mat'),'expt')
            
            % run experiment
            expFun(dataPath,expt)
            
            dataPath = fileparts(strip(tempdirs{d},'right',filesep))
            expPath = fileparts(strip(dataPath,'right',filesep))
            break;
        end
    end
    expPath = [];
end



end

