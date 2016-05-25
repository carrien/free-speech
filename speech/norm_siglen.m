function [normed] = norm_siglen(sig,normedlen)
%NORM_TRACKLEN  Normalize formant track to new length.
%   NORM_TRACKLEN(FTRACK,NORMEDLEN) uses interpolation to return a NORMED
%   track of length NORMEDLEN.

if nargin < 2, normedlen = 25; end

normed = interp1(sig,1:length(sig)/normedlen:length(sig));

end
