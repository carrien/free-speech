function [filepaths] = get_eventfiles(dataPath)
%GET_EVENTFILES  Get paths event files in a directory.

if nargin < 1 || isempty(dataPath), dataPath = cd; end

% list event files in directory
filestruct = dir(fullfile(dataPath,'events_aphsis*.mat'));
if isempty(filestruct)
    error('No matching event marker files found.')
end
fprintf('%d matching event files found.\n',length(filestruct));
filenames = {filestruct.name};

% strip .mat and sort
names = cell(1,length(filenames));
for i=1:length(filenames)
    [~,names{i}] = fileparts(filenames{i});
end
names = sort(names);

% prepend dataPath and append extension
filepaths = cell(1,length(names));
for i=1:length(filenames)
    filenames{i} = sprintf('%s.mat',names{i});
    filepaths{i} = fullfile(dataPath,filenames{i});
end
