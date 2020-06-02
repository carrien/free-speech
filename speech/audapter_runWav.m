function [dataOut] = audapter_runWav(wavfile,nlpc)
%AUDAPTER_RUNWAV  Process a wav file in Audapter offline ('runFrame') mode.
%   AUDAPTER_RUNWAV(WAVFILE,NLPC) runs the wave file WAVFILE through
%   Audapter's offline mode using the LPC order given in NLPC.

if nargin < 2, nlpc = 15; end

[y,fs] = audioread(wavfile);
data.signalIn = y;
data.params.sr = fs;
p.nlpc = nlpc;
[dataOut] = audapter_runFrames(data,p);
