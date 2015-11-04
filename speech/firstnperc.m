function [firstn] = firstnperc(signal,n,startbuff)
%FIRSTNPERC   Returns the first n% of input signal.
%   FIRSTNPERC(SIGNAL,N,STARTBUFF) returns the first N% of input signal
%   SIGNAL, excluding a buffer of STARTBUFF percent.

if ~(n > startbuff)
    error('Start buffer is greater than or equal to the first %d percent of the signal.',n)
elseif ~(n > 0) || n > 100
    error('Percent of signal to be returned must be between 0 than 100.')
end
    
firstlen = ceil(n*.01*length(signal));
start = ceil(startbuff*.01*length(signal));
firstn = signal(start+1:firstlen);