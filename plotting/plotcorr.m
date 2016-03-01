function [r,p,pfit] = plotcorr(x,y,loc,tail,corrtype)
%PLOTCORR  Plot the correlation and best fit line for two vectors.
%   PLOTCORR(X,Y,LOC,TAIL,CORRTYPE)

if nargin < 3 || isempty(loc), loc = 'Best'; end
if nargin < 4 || isempty(tail), tail = 'both'; end
if nargin < 4 || isempty(corrtype), corrtype = 'Pearson'; end

if size(x,1)==1, x = x'; end
if size(y,1)==1, y = y'; end

if sum(isnan(x)) || sum(isnan(y)) %remove NaNs
    if isnan(x) == isnan(y)
        x = x(~isnan(x));
        y = y(~isnan(y));
    elseif ~sum(isnan(x))
        x = x(~isnan(y));
        y = y(~isnan(y));
    elseif ~sum(isnan(y))
        y = y(~isnan(x));
        x = x(~isnan(x));
    else
        error('NaNs do not line up in data to be correlated.')
    end
end

[r,p] = corr(x,y,'type',corrtype,'tail',tail);
plot(x,y,'k.')
pfit = polyfit(x,y,1);
hold on;
%axis equal
ax = axis; xrange = ax(1)-5:ax(2)+5;
plot(xrange,xrange*pfit(1)+pfit(2),'k'); axis(ax);
legend({sprintf('r = %.3f',r),sprintf('p = %.3f',p)},'Location',loc)

xlab = inputname(1);
ylab = inputname(2);
xlabel(xlab)
ylabel(ylab)