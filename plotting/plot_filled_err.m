function plot_filled_err(t,sig,err,color,facealpha,edgealpha)
%PLOT_FILLED_ERR  Plot error bars as shaded regions around a signal.
%   PLOT_FILLED_ERR(T,SIG,ERR,COLOR,FACEALPHA,EDGEALPHA) fills in an error
%   region around a mean signal SIG with COLOR.  SIG and ERR are row
%   vectors; SIG+ERR and SIG-ERR form the bounds of the shaded region.
%
% cn 7/2011

if isempty(t), t = 1:length(sig); end
if nargin < 4 || isempty(color), color = [1 0 0]; end
if nargin < 5, facealpha = .35; end
if nargin < 6, edgealpha = 0; end

yvals = [sig+err fliplr(sig-err)];
yvals(isnan(yvals)) = 0;

fill([t fliplr(t)], yvals, color, 'EdgeColor', color, 'FaceAlpha', facealpha, 'EdgeAlpha', edgealpha);