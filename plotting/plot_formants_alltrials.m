function [] = plot_formants_alltrials(dataVals,m,n)
%PLOT_FORMANTS_ALLTRIALS  Plot formant tracks from multiple trials in grid.
%   PLOT_FORMANTS_ALLTRIALS(DATAVALS,M,N) plots the formant tracks from
%   each trial in DATAVALS in an MxN grid, generating multiple figure
%   windows if necessary to display all the trials.  M and N are optional
%   and will default to the square root of the number of trials, up to a
%   maximum of 15.

len = length(dataVals);
if nargin < 3
    m = min(ceil(sqrt(len)),15); n = m;
end

for j = 1:ceil(len/(m*n))
figure;
ha = tight_subplot(m,n,.005,.005,[.03 .005]);
for i=1:min(m*n,len-m*n*(j-1))
    axes(ha(i));
    plot(dataVals(i+(m*n)*(j-1)).f1,'b','LineWidth',2)
    hold on;
    plot(dataVals(i+(m*n)*(j-1)).f2,'r','LineWidth',2)
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    if mod(i,n) == 1
        ylabel(num2str(i+(m*n)*(j-1)))
    end
end
end