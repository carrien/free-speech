function [sinewave,t] = get_sine(freq,dur,fs,phaseoffset)
%GET_SINE  Create sine wave of specified frequency, duration, sampling, and phase offset.
%  GET_SINE(FREQ,DUR,FS,PHASEOFFSET) returns a sine wave SINEWAVE with
%  frequency FREQ (Hz), duration DUR (s), sampling rate FS (samples/s), and
%  phase offset PHASEOFFSET (radians).

if nargin < 2 || isempty(dur), dur = 1; end
if nargin < 3 || isempty(fs), fs = 11025; end
if nargin < 4 || isempty(phaseoffset), phaseoffset = 0; end

t = 0:1/fs:dur;
sinewave = sin(freq*2*pi*t + phaseoffset);

end
