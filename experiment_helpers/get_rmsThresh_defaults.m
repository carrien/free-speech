function params = get_rmsThresh_defaults(phase, bUsePeak)
% This function holds default parameters used during an experiment to
% display if the participant's amplitude is acceptable. These values are
% saved in expt.amp and referenced in check_rmsThresh.
%
% This function is siloed since it is referenced in multiple places, and
% it gives space for context.
%
% Input arguments:
%   * phase. A prescribed list of phases, which meets certain needs.
%       Currently supports 'main' and 'pretest'
%   * bUsePeak. Goes directly into params.bUsePeak, which corresponds to
%       expt.amp.bUsePeak. If this is 1, then check_rmsThresh will use the
%       peak amplitude in the signal to find an "RMS value." If 0,
%       check_rmsThresh will use the mean RMS during either OST-based onset
%       and offset, or derived onset and offset based on other signal
%       properties, to find the "RMS value."
%
% Output arguments:
%   * params. Can be saved directly to expt.amp.
%
% Parameters:
%   * targetRMS. If the RMS value is below this threshold, check_rmsThresh
%       will return bGoodTrial as 0.
%   * limits. A 2x2 array of 4 values: The first row is for "good" values,
%       the second row is for "warn" values. The first column is for lower
%       limits, the second column is for upper limits. So, like this:
%            [GoodLow, GoodHi;
%             WarnLow, WarnHi]
%       In check_rmsThresh, a patch will be drawn in green for Good values
%       between the low and hi limits, and a patch in yellow between the
%       Warn limits.
%
%       To not draw a patch, use the same value (such as 0) for Low and Hi.
%
%       2023-05 Chris Naber init.

if nargin < 1 || isempty(phase)
    phase = 'main';
end
if nargin < 2 || isempty(bUsePeak)
    bUsePeak = 0;
end

params.bUsePeak = bUsePeak;

if strcmp(phase, 'pretest')
    params.targetRMS = 0;
    % during pretest phase, green region is 80-86 dBA on SMNG hardware.
    % Warn region is +/- another 1.5 dBA.
    params.limits = [0.042, 0.060; 0.037, 0.065];
elseif strcmp(phase, 'main')
    params.targetRMS = 0.037;
    % during main phase, don't use warn region. have very wide good region.
    params.limits = [0.037, 0.100; 0 0];
else
    error('Invalid phase name.');
end

end
