function [str] = sprint_tstat(p,stats)
%SPRINT_TSTAT  Print t-statistic in formatted string.
%   SPRINT_TSTAT(P,STATS)

str = sprintf('t(%d) = %f, p = %f',stats.df,stats.tstat,p);

end

