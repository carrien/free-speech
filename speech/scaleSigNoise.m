function [scaledSig] = scaleSigNoise(sig,noise,snr,onsetInd,offsetInd)
%SCALESIGNOISE  Scale signal to a given SNR.

if nargin < 3 || isempty(snr), snr = 0; end
if nargin < 4 || isempty(onsetInd), onsetInd = 1; end
if nargin < 5 || isempty(offsetInd), offsetInd = length(sig); end

% excise portion to use for scaling
sigPortion = sig(onsetInd:offsetInd);
noisePortion = noise(onsetInd:offsetInd);

% get rms
rmsSig = rms(sigPortion);
rmsNoise = rms(noisePortion);

% calculate scale factor
scaleFactor = (rmsNoise/rmsSig)*10^(snr/20); % from SNR = 20*log(signal/noise)
scaledSig = sig*scaleFactor;

end
