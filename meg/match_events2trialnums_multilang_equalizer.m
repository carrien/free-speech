function [trialinds] = match_events2trialnums_multilang_equalizer(expt,allevents,newEventInfo,cond,subMegDataPath,equalized)
%MATCH_EVENTS2TRIALNUMS  Match experiment events to trial numbers.
%   MATCH_EVENTS2TRIALNUMS(EXPT,EVENTS,NEWEVENTINFO)
%   cond can equal, for example, language

% check for case/Case in speak/Speak--maybe try strcmpi?

if nargin < 6 || isempty(equalized), equalized = 1; end

nwords = length(expt.words);
eventnames = {allevents.label};

% find speak, listen, and visual event indices
speakstim_inds = zeros(1,nwords);
listenstim_inds = zeros(1,nwords);
speak_inds = zeros(1,nwords);
listen_inds = zeros(1,nwords);
for w=1:nwords
    if strcmpi(cond,'English')
    speakstim_inds(w) = find(strcmp(eventnames,num2str(w)));
    listenstim_inds(w) = find(strcmp(eventnames,num2str(w+nwords)));
    else
    speakstim_inds(w) = find(strcmp(eventnames,num2str(w+(2*nwords))));
    listenstim_inds(w) = find(strcmp(eventnames,num2str(w+(3*nwords))));
    end
    speak_inds(w) = find(strcmp(eventnames,sprintf('%sSpeak%d',char(cond),w)));
    listen_inds(w) = find(strcmp(eventnames,sprintf('%sListen%d',char(cond),w)));
end
speakstim_events = allevents(speakstim_inds);
listenstim_events = allevents(listenstim_inds);
speak_events = allevents(speak_inds);
listen_events = allevents(listen_inds);

% get time of each event
speakstim_eventtimes = sort([speakstim_events.times]);
listenstim_eventtimes = sort([listenstim_events.times]);
speak_eventtimes = [speak_events.times];
speak_eventsamples = [speak_events.samples];
speak_fileinds = [speak_events.fileind];
[speak_eventtimes,inds] = sort(speak_eventtimes);
speak_eventsamples = speak_eventsamples(inds);
speak_fileinds = speak_fileinds(inds);
listen_eventtimes = [listen_events.times];
listen_eventsamples = [listen_events.samples];
listen_fileinds = [listen_events.fileind];
[listen_eventtimes,inds] = sort(listen_eventtimes);
listen_eventsamples = listen_eventsamples(inds);
listen_fileinds = listen_fileinds(inds);

% for each event, find the time range that matches it
speak_trialnums = zeros(1,length(speak_eventtimes));
listen_trialnums = zeros(1,length(listen_eventtimes));
for i=1:length(speak_eventtimes)
    diffs = speak_eventtimes(i) - speakstim_eventtimes;
    pos = find(diffs > 0); % first positive different is preceding event
    if ~isempty(pos)
        speak_trialnums(i) = pos(end);
    end
end
for i=1:length(listen_eventtimes)
    diffs = listen_eventtimes(i) - listenstim_eventtimes;
    pos = find(diffs > 0.02); % was: > 0); % first positive difference is preceding event, but add buffer for late trials
    if ~isempty(pos)
        listen_trialnums(i) = pos(end);
    else
        warning('No preceding stim found for event at %d ms.',listen_eventtimes(i));
    end
end
[~,ia]=unique(listen_trialnums);
overlaps = setdiff(1:length(listen_trialnums),ia);
if ~isempty(overlaps)
    error('%d repeat trials found at times %s in files %s',length(overlaps),mat2str(listen_eventtimes(overlaps)),mat2str(listen_fileinds(overlaps)));
end

if equalized
    speak_mismatches = setdiff(speak_trialnums,listen_trialnums); % speaks that are not in listens!
    [~,spkinds2rm] = ismember(speak_mismatches,speak_trialnums);
    speak_trialnums(spkinds2rm) = [];
    speak_fileinds(spkinds2rm) = [];
    listen_mismatches = setdiff(listen_trialnums,speak_trialnums); % listens that are not in speaks
    [~,lisinds2rm] = ismember(listen_mismatches,listen_trialnums);
    listen_trialnums(lisinds2rm) = [];
    listen_fileinds(lisinds2rm) = [];
end



% create new event structs
for f = 1:length(unique([speak_fileinds listen_fileinds])); % for each file to write
    events = struct;
    for e = 1:length(newEventInfo)                          % for each condition
        events(e).label = newEventInfo(e).name;
        events(e).color = newEventInfo(e).color;
        
        %        if strncmp(events(e).label,'speak',5)
        if strfind(events(e).label,sprintf('%sSpeak',cond))
            [trialinds{e}{f},~,ind_speak_events] = intersect(newEventInfo(e).trialinds,speak_trialnums(speak_fileinds==f));
            for i=1:f-1
                ind_speak_events = ind_speak_events + length(find(speak_fileinds==i));
            end
            events(e).epochs = ones(1,length(trialinds{e}{f}));
            events(e).samples = speak_eventsamples(ind_speak_events);
            events(e).times = speak_eventtimes(ind_speak_events);
            %        elseif strncmp(events(e).label,'listen',6)
        elseif strfind(events(e).label,sprintf('%sListen',cond))
            [trialinds{e}{f},~,ind_listen_events] = intersect(newEventInfo(e).trialinds,listen_trialnums(listen_fileinds==f));
            for i=1:f-1
                ind_listen_events = ind_listen_events + length(find(listen_fileinds==i));
            end
            events(e).epochs = ones(1,length(trialinds{e}{f}));
            events(e).samples = listen_eventsamples(ind_listen_events);
            events(e).times = listen_eventtimes(ind_listen_events);
        end
        
        events(e).reactTimes = [];
        events(e).select = 1;
    end
    
    % remove empty elements from struct
    for e0 = length(events):-1:1
        if isempty(events(e0).times)
            events(e0) = [];
        end
    end
    
    % save each event file
    dataPath = subMegDataPath;
    %dataPath = fullfile(get_megLoadPath('cais',sid),char(cond)) %fullfile('/Volumes/smng/experiments/',expt.name,'megdata',sid, char(cond)) % switch back to expt.snum
    savefile = fullfile(dataPath,['events_' newEventInfo.name '_' num2str(f-1) '.mat']);
    bSave = savecheck(savefile);
    if bSave
        save(savefile,'events');
        fprintf('Event file saved to %s\n',savefile);
    end
end

for e=1:length(trialinds)
    trialinds{e} = unique([trialinds{e}{:}])
end


npairs = (length(trialinds))/2;
tri2rm = cell(1,length(trialinds));
inds2rm = cell(1,length(trialinds));
newTrialinds = cell(1,length(trialinds));

for i = 1:npairs
    mismatches = setdiff(trialinds{i},trialinds{i+npairs}) % speaks that are not in listens!
    if ~isempty(mismatches)
        tri2rm{i} = mismatches;
    end
    mismatches = setdiff(trialinds{i+npairs},trialinds{i}); % listens that are not in speaks!
    if ~isempty(mismatches)
        tri2rm{i+npairs} = mismatches;
    end
end

for i = 1:length(trialinds)
    if ~isempty(tri2rm{i})
        [~,rminds] = ismember(tri2rm{i},trialinds{i}) % get indices (not trialnums) of trials to be removed.
        trialinds{i}(rminds) = [];
        inds2rm{i} = rminds; % indices of trialinds{i} that are getting removed; NOT trial numbers.
    end
    newTrialinds{i} = trialinds{i};
end


