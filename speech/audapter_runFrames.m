function [dataOut] = audapter_runFrames(data,p)
%AUDAPTER_RUNFRAMES  Process data in Audapter offline ('runFrame') mode.
%   AUDAPTER_RUNFRAMES(DATA,P) runs audio through Audapter's offline
%   mode using the Audapter parameters provided in P.  The input DATA is a struct
%   array with fields 'signalIn' and 'params' (i.e., the same format
%   returned by Audapter).

% set Audapter param fields
if ~isempty(p.gender)
    gender = p.gender;
else
    gender = 'female'; % default gender is female
end
pDefault = getAudapterDefaultParams(gender);
downFact = 3; % Downsampling factor
fsNoDS = 48000; % Sampling rate, before downsampling
frameLenNoDS = 96;  % Frame length before downsampling (# of samples)
pDefault.downFact = downFact;
pDefault.sr = fsNoDS / downFact;
pDefault.frameLen = frameLenNoDS / downFact;

if nargin < 2 
    p = pDefault;
else
    p = add2struct(pDefault,p);    
end


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

% preserve original (or calculated) OST values
dataOut = AudapterIO('getData');
if isfield(data,'ost_stat')
    dataOut.ost_stat = data.ost_stat; 
end
if isfield(data,'calcOST')
    dataOut.calcOST = data.calcOST; 
end
if isfield(data,'ost_calc')
    dataOut.calcOST = data.ost_calc; 
end
