function [ ] = match_events(expt,events)
%MATCH_EVENTS  Match experiment trials with MEG events.
%   MATCH_EVENTS(EXPT,EVENTS)

nwords = length(expt.words);
eventnames = {events.label};

for w=1:nwords
    speakstim_inds(w) = find(strcmp(eventnames,num2str(w)));
    listenstim_inds(w) = find(strcmp(eventnames,num2str(w+nwords)));
    speak_inds(w) = find(strcmp(eventnames,sprintf('speak%d',w)));
    listen_inds(w) = find(strcmp(eventnames,sprintf('listen%d',w)));
end

speakstim_events = events(speakstim_inds);
listenstim_events = events(listenstim_inds);
speak_events = events(speak_inds);
listen_events = events(listen_inds);

allWords = expt.allWords;

for w=1:nwords
    if length(speakstim_events(w).times) ~= length(speak_events(w).times)
        warning('Speak event mismatch')
    end
    if length(listenstim_events(w).times) ~= length(listen_events(w).times)
        warning('Listen event mismatch (%s)',listen_events(w).label)
    end
end
