function [err] = get_errorbars(sig,errortype,ntrials,stdtype)
% GET_ERRORBARS  Calculates error bars of different types.
%   GET_ERRORBARS(SIG,ERRORTYPE,NTRIALS,STDTYPE) calculates error bars of
%   type ERRORTYPE. The signal SIG is a matrix of timepoints x trials.

if nargin < 3 || isempty(ntrials), ntrials = size(sig,2); end
if nargin < 4, stdtype = 0; end

if strcmp(errortype,'ci')
    err = calcci(sig);
elseif strcmp(errortype,'se')
    err = nanstd(sig,stdtype,2)./sqrt(ntrials);
elseif strcmp(errortype,'std')
    err = nanstd(sig,stdtype,2);
else
    error('Unrecognized error type ''%s''.',errortype)
end
