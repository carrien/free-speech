function [dataOut] = audapter_runFrames(data,nlpc)
%AUDAPTER_RUNFRAMES  Process data in Audapter offline ('runFrame') mode.
%   AUDAPTER_RUNFRAMES(DATA,NLPC) runs audio through Audapter's offline
%   mode using the LPC order given in NLPC.  The input DATA is a struct
%   array with fields 'signalIn' and 'params' (i.e., the same format
%   returned by Audapter).

if nargin < 2, nlpc = 15; end

% set Audapter param fields
gender = 'female'; % dummy var for getting default params; will be overwritten by nlpc
p = getAudapterDefaultParams(gender);
downFact = 3; % Downsampling factor
fsNoDS = 48000; % Sampling rate, before downsampling
frameLenNoDS = 96;  % Frame length before downsampling (# of samples)
p.downFact = downFact;
p.sr = fsNoDS / downFact;
p.frameLen = frameLenNoDS / downFact;
p.bShift = 0;
p.nLPC = nlpc;

% Nullify OST and PCF, so that they won't override the perturbation field
Audapter('ost', '', 0);
Audapter('pcf', '', 0);

% init Audapter
AudapterIO('init', p);    % Initialize
AudapterIO('reset');   % Reset;

% run Audapter on the input signal
sigIn = data.signalIn;
fs = data.params.sr;
sigIn = resample(sigIn, fsNoDS, fs);
sigInCell = makecell(sigIn, frameLenNoDS);
for n = 1:length(sigInCell)
    Audapter('runFrame', sigInCell{n});
end

dataOut = AudapterIO('getData');
