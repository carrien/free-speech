function [sinewave,t] = get_sine(freq,amp,phaseoffset,dur,fs)
%GET_SINE  Create sine wave.
%  GET_SINE(FREQ,AMP,PHASEOFFSET,DUR,FS) returns a sine wave SINEWAVE with
%  frequency FREQ (Hz), amplitude AMP, phase offset PHASEOFFSET (radians),
%  duration DUR (s), and sampling rate FS (samples/s).

if nargin < 2 || isempty(amp), amp = 1; end
if nargin < 3 || isempty(phaseoffset), phaseoffset = 0; end
if nargin < 4 || isempty(dur), dur = 1; end
if nargin < 5 || isempty(fs), fs = 11025; end

t = 1/fs:1/fs:dur;
sinewave = amp*sin(freq*2*pi*t + phaseoffset);

end
