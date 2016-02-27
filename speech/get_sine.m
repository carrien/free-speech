function [sinewave] = get_sine(freq,dur,fs)
%GET_SINE  Create sine wave of specified frequency, duration, and sampling.

if nargin < 2 || isempty(dur), dur = 1; end
if nargin < 3 || isempty(fs), fs = 11025; end

t = 0:1/fs:dur;
sinewave = sin(freq*2*pi*t);

end
