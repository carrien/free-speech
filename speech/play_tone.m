function [ ] = play_tone(w,amp,phaseoffset,dur,fs,bRamp)
%PLAY_TONE  Play a sine wave tone.
%   PLAY_TONE(W,DUR,FS) plays a sine wave tone of frequency W Hz, duration
%   DUR seconds, and amplitude AMP dB at sampling rate FS.

if nargin < 2 || isempty(amp), amp = 1; end
if nargin < 3 || isempty(phaseoffset), phaseoffset = 0; end
if nargin < 4 || isempty(dur), dur = 1; end
if nargin < 5 || isempty(fs), fs = 44100; end
if nargin < 6 || isempty(bRamp), bRamp = 0; end

if length(amp) < length(w)
    amp = amp(1)*ones(1,length(w));
end
if length(phaseoffset) < length(w)
    phaseoffset = phaseoffset(1)*ones(1,length(w));
end

t = 1/fs:1/fs:dur;
y = zeros(1,length(t));
for i=1:length(w)
    y = y + get_sine(w(i),amp(i),phaseoffset(i),dur,fs);
end

if bRamp
    t = 0:1/fs:dur;
    env = sin(pi*t/t(length(t)));
    y = y .* env;
end
sound(y,fs);
pause(dur);
