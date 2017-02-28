function [] = plot_audiogram
%PLOT_AUDIOGRAM Plot hearing screening values where x is the frequency and 
%y is the hearing threshold in decibels.

load audiogram.mat
%manually entered audiogram.right = [5 values];audiogram.left = [5 values];
%and saved as audiogram.mat for each subject ...any way to automate this?
frequency = [250 500 1000 2000 4000];
A = {audiogram.right, audiogram.left};
T = {'Right Audiogram', 'Left Audiogram'};
M = {'r-o', 'b-x'};

for i = 1:2
    subplot(1,2,i)
    plot(frequency,A{i},M{i},'MarkerSize',8)
    title(T{i})
    xlabel('Frequency (Hz)')
    ylabel('Decibels (dB)')
    set(gca,'XAxisLocation','top')
    set(gca,'Ydir','reverse')
    grid on 
    set(gca,'YLim',[0,100])
    set(gca,'XLim',[0,4000])
    set(gca,'XScale','log')
    set(gca,'XTick',frequency)
    set(gca,'XMinorGrid','off')
    set(gca,'XMinorTick','off')
    axis square  
end