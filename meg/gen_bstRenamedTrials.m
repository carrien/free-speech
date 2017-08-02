function [ ] = gen_bstRenamedTrials(dataPath,trialnums,newDataPath)
%GEN_BSTRENAMEDTRIALS  Copies and renumbers brainstorm trial files.
%   GEN_BSTRENAMEDTRIALS(DATAPATH,NEWDATAPATH) copies mat files from
%   DATAPATH to NEWDATAPATH, which must be an absolute path if it doesn't
%   already exist, renaming the files to reflect the trial numbers in
%   TRIALNUMS.

% check if new dir exists
if exist(newDataPath,'dir')
    bSave = savecheck(newDataPath,'dir');
    if ~bSave, return; end
else
    mkdir(newDataPath)
end

% get all files in original dir
filter = fullfile(dataPath,'data_*.mat');
files = dir(filter);
filenames = {files.name};
% split off trial suffix -- can use "split" without for loop in Matlab 2014+
suffixes = cell(length(files),1);
for f=1:length(files)
    C = strsplit(filenames{f},'trial'); % use "trial" as delimiter for file names
    if ~exist('prefix','var')
        prefix = C{1};
    elseif ~strcmp(prefix,C{1})
        error('Prefix of file %s doesn''t match others in the folder.',filenames{f})
    end
    suffixes{f} = C{end};
end

nfifs = 3; % set to 3 for now but can find programmatically later

% use regular expression to find file order -- can use "endsWith" in Matlab 2016+
fif0 = 1:length(filenames);
for fif=1:nfifs-1
    suffix = sprintf('_%02d.mat$',fif+1);                       % e.g. "_03.mat")
    extras{fif} = ~cellfun(@isempty, regexp(filenames,suffix)); % find indices of names with suffix
    fif0 = setdiff(fif0,extras{fif});                           % remove these indices from fif0
end

sortedinds = fif0;
for fif=1:nfifs-1
    sortedinds = [sortedinds extras{fif}];
end
sortedfiles = filenames(sortedinds);

for i=1:length(sortedfiles)
    oldfilepath = fullfile(dataPath,sortedfiles{i});
    newfilepath = fullfile(newDataPath,sprintf('%s_trial%03d',prefix,trialnums(i)));
    command = sprintf('cp %s %s',oldfilepath,newfilepath);
    system(command)
end
