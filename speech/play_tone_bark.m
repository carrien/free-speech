function [ ] = play_tone_bark(w_bark,amp,phaseoffset,dur,fs,bRamp)
%PLAY_TONE  Play a sine wave tone with frequency specified in Bark.
%   PLAY_TONE(W_BARK,DUR,AMP,FS,BRAMP) plays a sine wave tone of frequency
%   W Bark, duration DUR seconds, and amplitude AMP dB at sampling rate FS.
%   If BRAMP = 1, the sound will ramp on and off with a sin wave carrier.

if nargin < 2, amp = []; end
if nargin < 3, phaseoffset = []; end
if nargin < 4, dur = []; end
if nargin < 5, fs = []; end
if nargin < 6, bRamp = []; end

w_hz = bark2hz(w_bark);
play_tone(w_hz,amp,phaseoffset,dur,fs,bRamp)
