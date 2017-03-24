function [ ] = play_tone(w,dur,amp,fs,bRamp,bComplex)
%PLAY_TONE  Play a sine wave tone.
%   PLAY_TONE(W,DUR,FS) plays a sine wave tone of frequency W Hz, duration
%   DUR seconds, and amplitude AMP dB at sampling rate FS.

if nargin < 2 || isempty(dur), dur = 1; end
if nargin < 3 || isempty(amp), amp = 1; end
if nargin < 4 || isempty(fs), fs = 11025; end
if nargin < 5 || isempty(bRamp), bRamp = 0; end
if nargin < 6, bComplex = 0; end

if ~bComplex
    y = amp*get_sine(w,dur,fs); 
else
    y = amp*(get_sine(w,dur,fs) + get_sine(2*w,dur,fs) + get_sine(3*w,dur,fs));
end

if bRamp
    t = 0:1/fs:dur;
    env = sin(pi*t/t(length(t)));
    y = y .* env;
end
sound(y,fs);
