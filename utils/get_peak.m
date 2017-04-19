function [peak,peaktime,peakind] = get_peak(sig,taxis,trange)
%GET_PEAK  Returns the signal peak in a specified window.
%   GET_PEAK(SIG,TAXIS,TRANGE) returns the maximum value of the signal SIG
%   in the time range TRANGE given a time axis TAXIS, along with the time
%   and index of that maximum with respect to the whole signal.
%
% CN 3/2012

if isempty(taxis), taxis = 1:length(sig); end
if length(trange) > 2, trange = [min(trange) max(trange)]; end

% convert time range to sample range
range = get_index_at_time(taxis,trange(1)):get_index_at_time(taxis,trange(2));

% get peak and index
[peak,peakind] = max(sig(range));
peakind = peakind+range(1)-1;
peaktime = taxis(peakind);