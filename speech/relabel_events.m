function relabel_events(eventNames,dataPath,trialnums,buffertype,folderSuffix)
%Function to relabel event names in data processed with audioGUI in case of
%a naming error. Takes as input an array of character string EVENTNAMES.
%BP 15 OCT 2021.
if nargin < 1 || isempty(eventNames) || ~iscellstr(eventNames)
    error('You must enter new event names as a cell array of character strings!')
end
if nargin < 2 || isempty(dataPath), dataPath = cd; end
if nargin < 3, trialnums = []; end
if nargin < 4 || isempty(buffertype), buffertype = 'signalIn'; end
if nargin < 5, folderSuffix = []; end

% set trial folder
if isempty(folderSuffix)
    if strcmp(buffertype,'signalIn')
        trialfolder = 'trials';
    else
        trialfolder = sprintf('trials_%s',buffertype);
    end
else
    if strcmp(buffertype,'signalIn')
        trialfolder = sprintf('trials_%s', folderSuffix);
    else
        trialfolder = sprintf('trials_%s_%s',folderSuffix,buffertype);
    end
end

%get all trials if trialnums is emptry
if isempty(trialnums)
    fileList = dir(trialfolder);
    fileList = fileList(~[fileList.isdir]);
    for t = 1:length(fileList)
        trialnums(t) = str2double(fileList(t).name(1:end-4));
    end
    trialnums = sort(trialnums);
end

for t = trialnums
    load(fullfile(dataPath,trialfolder,sprintf('%d.mat',trialnums(t))));
    if size(trialparams.event_params.user_event_names,2) ~= size(eventNames,2)
        warning('Number of events in trial %d does not equal number of specified events',t)
    else
        fprintf('Changing labels on trial %d.\n',t)
        trialparams.event_params.user_event_names = eventNames;
    end
    save(fullfile(dataPath,trialfolder,sprintf('%d.mat',trialnums(t))),'sigmat','trialparams')
end