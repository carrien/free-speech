function [h_sub] = get_subfigs_audapter(h,bPlotAmp)

if nargin < 2 || isempty(bPlotAmp); bPlotAmp = 0;end

figure(h)

h_sub(1) = subplot(5,4,1:4); %stimulus number window
set(h_sub(1),'Color',[.75 .75 .75])
axis square off
xlim([0 1]);
ylim([0 1]);

if ~bPlotAmp
    h_sub(2) = subplot(5,4,5:20); %participant performance track window
    set(h_sub(2),'Color',[.75 .75 .75])
    axis square off
    xlim([0 1]);
    ylim([0 1]);
else
    h_sub(2) = subplot(5,4,5:12); %spectrogram window
    set(h_sub(2),'Color',[.75 .75 .75])
    axis square off
    xlim([0 1]);
    ylim([0 1]);
    plot(1:100)

    h_sub(3) = subplot(5,4,13:20); %amplitude window
    set(h_sub(3),'Color',[.75 .75 .75])
    axis square off
    xlim([0 1]);
    ylim([0 1]);
    plot(1:100)
end