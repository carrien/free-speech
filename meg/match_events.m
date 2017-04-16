function [ ] = match_events(expt,allevents,newEventInfo)
%MATCH_EVENTS  Match experiment trials with MEG events.
%   MATCH_EVENTS(EXPT,EVENTS,NEWEVENTINFO)

nwords = length(expt.words);
eventnames = {allevents.label};

% find speak and listen event indices
speak_inds = zeros(1,nwords);
listen_inds = zeros(1,nwords);
for w=1:nwords
    %    speakstim_inds(w) = find(strcmp(eventnames,num2str(w)));
    %    listenstim_inds(w) = find(strcmp(eventnames,num2str(w+nwords)));
    speak_inds(w) = find(strcmp(eventnames,sprintf('speak%d',w)));
    listen_inds(w) = find(strcmp(eventnames,sprintf('listen%d',w)));
end
speak_events = allevents(speak_inds);
listen_events = allevents(listen_inds);

% get time of each event
% speak
speak_eventtimes = [speak_events.times];
speak_eventsamples = [speak_events.samples];
speak_eventorder = [speak_events.eventind];
speak_fileinds = [speak_events.fileind];
[speak_eventtimes,inds] = sort(speak_eventtimes);
speak_eventsamples = speak_eventsamples(inds);
speak_eventorder = speak_eventorder(inds);
speak_eventorder = speak_eventorder - speak_inds(1) + 1; % convent to 1,2,3
speak_fileinds = speak_fileinds(inds);
% listen
listen_eventtimes = [listen_events.times];
listen_eventsamples = [listen_events.samples];
listen_eventorder = [listen_events.eventind];
listen_fileinds = [listen_events.fileind];
[listen_eventtimes,inds] = sort(listen_eventtimes);
listen_eventsamples = listen_eventsamples(inds);
listen_eventorder = listen_eventorder(inds);
listen_eventorder = listen_eventorder - listen_inds(1) + 1; % convert to 1,2,3
listen_fileinds = listen_fileinds(inds);

% check that order matches expt file
if length(expt.allWords) ~= length(speak_eventorder)
    warning('Word and speak event lists do not have the same number of elements. Checking for earliest mismatch.');
    figure; plot(speak_eventorder)
    hold on;
    plot(expt.allWords,'g'); % ground truth
    legend({'triggers in event order','presented words'});=======
>>>>>>> 995c3f715bf869c86e950622228278e628376c14

    % find first mismatching element
    len = min(length(expt.allWords),length(speak_eventorder));
    mismatch = find(expt.allWords(1:len) ~= speak_eventorder(1:len));
    error('First mismatch found at %d seconds (trial %d)',speak_eventtimes(mismatch(1)),mismatch(1));
elseif length(expt.allWords) ~= length(listen_eventorder)
    warning('Word and listen event lists do not have the same number of elements. Checking for earliest mismatch.');
    figure; plot(listen_eventorder)
    hold on;
    plot(expt.allWords,'g'); % ground truth
    legend({'triggers in event order','presented words'});
    % find first mismatching element
    len = min(length(expt.allWords),length(listen_eventorder));
    mismatch = find(expt.allWords(1:len) ~= listen_eventorder(1:len));
    error('First mismatch found at %d seconds (trial %d)',listen_eventtimes(mismatch(1)),mismatch(1));
elseif expt.allWords ~= speak_eventorder
    error('Word and event lists are the same length but do not match!')
elseif speak_eventorder ~= listen_eventorder
    error('Speak and listen event lists do not match!')
else
    fprintf('All %d events match experiment file.\n',length(speak_eventorder))
end

% for w=1:nwords
%     if length(speakstim_events(w).times) ~= length(speak_events(w).times)
%         warning('Speak event mismatch')
%     end
%     if length(listenstim_events(w).times) ~= length(listen_events(w).times)
%         warning('Listen event mismatch (%s)',listen_events(w).label)

% create new event structs
for f = 1:length(unique([speak_fileinds listen_fileinds])); % for each file to write
    events = struct;
    for e = 1:length(newEventInfo)                          % for each condition
        events(e).label = newEventInfo(e).name;
        events(e).color = newEventInfo(e).color;

        if strncmp(events(e).label,'speak',5)
            trialinds = intersect(newEventInfo(e).trialinds,find(speak_fileinds==f));
            events(e).epochs = ones(1,length(trialinds));
            events(e).samples = speak_eventsamples(trialinds);
            events(e).times = speak_eventtimes(trialinds);
        elseif strncmp(events(e).label,'listen',6)
            trialinds = intersect(newEventInfo(e).trialinds,find(listen_fileinds==f));
            events(e).epochs = ones(1,length(trialinds));
            events(e).samples = listen_eventsamples(trialinds);
            events(e).times = listen_eventtimes(trialinds);
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
    dataPath = getMegSubjPath(expt.name,expt.snum);
    savefile = fullfile(dataPath,['events_' newEventInfo.name '_' num2str(f-1) '.mat']);
    bSave = savecheck(savefile);
    if bSave
        save(savefile,'events');
        fprintf('Event file saved to %s\n',savefile);
    end
end
