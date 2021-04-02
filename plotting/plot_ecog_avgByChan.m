function [h,alldat] = plot_ecog_avgByChan(neuralY,chnums,trialgroups)
%PLOT_ECOG_AVG  Plot

if nargin < 3, trialgroups.all = 1:length(neuralY); end

%pos = [1434 187 560 1042];
pos = [27 39 1212 732];
colors = {[.4 1 .4],[1 .4 .4],[.4 .4 1]};

if iscell(trialgroups)
    for i=1:length(trialgroups)
        fieldname = sprintf('field%02d',i);
        tg.(fieldname) = trialgroups{i};
    end
    trialgroups = tg;
elseif ~isstruct(trialgroups)
    error('Variable TRIALGROUPS must be a struct array or cell array.');
end

groupnames = fieldnames(trialgroups);

nplots = length(chnums);
ngroups = length(groupnames);
nrows = ceil(sqrt(nplots));

alldat(ngroups).ffx = [];
alldat(ngroups).rfx = [];

datnames = fieldnames(alldat);

t = -.5:1/200:1;

figure;
for i=1:nplots
    chdata = squeeze(neuralY(chnums(i),:,:))';
    subplot(nrows,nrows,i)
    for j=1:ngroups
        trialinds = trialgroups.(groupnames{j});
        dat = chdata(trialinds,1:301);
        alldat(j).ffx = [alldat(j).ffx; dat];
        sig = nanmean(dat);
        alldat(j).rfx = [alldat(j).rfx; sig];
        err = get_errorbars(dat','ci')';
        %t = 1:length(sig);
        plot_filled_err(t,sig,err,colors{j});
        hold on;
        plot(t,sig,'Color',colors{j});
        set(gca,'XTickLabel',[]);
        title(num2str(chnums(i)))
    end
    vline(.475,'k');
end

set(gcf,'MenuBar','none')
set(gcf,'Position',pos)

% plot averages across all chans
h = figure;
for j=1:ngroups
    dat = alldat(j).ffx;
    sig = nanmean(dat);
    err = get_errorbars(dat','ci');
    %t = 1:length(sig);
    hleg(j) = plot_filled_err(t,sig,err',colors{j});
    hold on;
    plot(t,sig,'Color',colors{j});
    %set(gca,'XTickLabel',[]);
    title(inputname(3))
    %vline(0,'k');
    box off;
    xlabel('time (s)')
end
legend(hleg,{'center','periphery'},'AutoUpdate','off');
legend box off
