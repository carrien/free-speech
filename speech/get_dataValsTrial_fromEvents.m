function [dataValsTrial] = get_dataValsTrial_fromEvents(sigmat,event_times,event_names)
%GET_DATAVALSTRIAL_FROMEVENTS  Extract dataVals tracks based on event list.
%   GET_DATAVALSTRIAL_FROMEVENTS(SIGMAT,EVENT_TIMES,EVENT_NAMES)

if nargin < 3, event_names = []; end

numUserEvents = length(event_times);
nSegments = numUserEvents - 1;

for s = 1:nSegments
    onset_time = event_times(s);
    offset_time = event_times(s+1);
    
    % find onset/offset indices for each track
    onsetIndf0 = get_index_at_time(sigmat.pitch_taxis,onset_time);
    offsetIndf0 = get_index_at_time(sigmat.pitch_taxis,offset_time);
    onsetIndfx = get_index_at_time(sigmat.ftrack_taxis,onset_time);
    offsetIndfx = get_index_at_time(sigmat.ftrack_taxis,offset_time);
    onsetIndAmp = get_index_at_time(sigmat.ampl_taxis,onset_time);
    offsetIndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time);

    % convert to dataVals struct
    dataValsTrial.f0{s} = sigmat.pitch(onsetIndf0:offsetIndf0)';                  % f0 track from onset to offset
    dataValsTrial.f1{s} = sigmat.ftrack(1,onsetIndfx:offsetIndfx)';               % f1 track from onset to offset
    dataValsTrial.f2{s} = sigmat.ftrack(2,onsetIndfx:offsetIndfx)';               % f2 track from onset to offset
    dataValsTrial.int{s} = sigmat.ampl(onsetIndAmp:offsetIndAmp)';                % intensity (rms amplitude) track from onset to offset
    dataValsTrial.pitch_taxis{s} = sigmat.pitch_taxis(onsetIndf0:offsetIndf0)';   % pitch time axis
    dataValsTrial.ftrack_taxis{s} = sigmat.ftrack_taxis(onsetIndfx:offsetIndfx)'; % formant time axis
    dataValsTrial.ampl_taxis{s} = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';   % amplitude time axis
    dataValsTrial.dur{s} = offset_time - onset_time;                              % duration
    
    if ~isempty(event_names)
        dataValsTrial.segment{s} = event_names{s};
    end
end

end %EOF

function [ind] = get_index_at_time(taxis,t)
% Simple binary search to find the corresponding t-axis value

low = 1; high = length(taxis);

while (high - low > 1)
    cand_ind = round((high+low)/2);
    if t < taxis(cand_ind)
        high = cand_ind;
    else
        low = cand_ind;
    end
end

if abs(high-t) > abs(low-t), ind = low;
else ind = high;
end

end