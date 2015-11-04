function [midn] = midnperc(signal,n)
% MIDNPERC  Returns the middle n% of input signal.

midlen = ceil(n*.01*length(signal));
start = ceil((length(signal)-midlen)/2);
midn = signal(start+1:start+midlen);