function [sinewave] = get_sine(freq,dur,fs)
%GET_SINE  Create sine wave of specified frequency, duration, and sampling.

t = 0:1/fs:dur;
sinewave = sin(freq*2*pi*t);

end

