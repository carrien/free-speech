function [ output_args ] = get_incData(expt,trialdir)
%GET_INCDATA generates incomplete data into single data file
%   generates a single data file from incomplete data using temp_trials
%   folder from incompleted experiments

if nargin < 1, expt = []; end
if nargin < 2,   ; end

% set output directory
% if isfield(expt,'dataPath')
%     outputdir = expt.dataPath;
% else
    warning('Setting output directory to current directory: %s\n',pwd);
    outputdir = pwd;
% end

% collect trials into one variable
alldata = struct;
fprintf('Processing data\n')
for i = 1:expt.ntrials
    trialfile = fullfile(trialdir,sprintf('%d.mat',i));
    if exist(trialfile,'file')
        load(trialfile,'data')
        names = fieldnames(data);
        for j = 1:length(names)
            alldata(i).(names{j}) = data.(names{j});
        end
    else
        warning('Trial %d not found.',i)
    end
end

% save data
fprintf('Saving data... ')
% clear data
data = alldata;
save(fullfile(outputdir,'data.mat'), 'data')
fprintf('saved.\n')

end

