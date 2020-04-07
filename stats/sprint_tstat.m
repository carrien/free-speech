function [str] = sprint_tstat(p,stats,pmin)
%SPRINT_TSTAT  Print t-statistic in formatted string.
%   SPRINT_TSTAT(P,STATS)

if nargin < 3, pmin = 0; end

tstr = sprintf('t(%d) = %.4f',stats.df,stats.tstat);
if p < pmin
    pstr = sprintf('p < %.4f',pmin);
else
    pstr = sprintf('p = %.4f',p);
end

str = sprintf('%s, %s',tstr,pstr);

end

