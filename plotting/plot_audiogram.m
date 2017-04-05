function [] = plot_audiogram(dataPaths)
%PLOT_AUDIOGRAM Plot hearing screening values where x is the frequency and 
%y is the hearing threshold in decibels.

if nargin < 1 || isempty(dataPaths), dataPaths = {cd}; end

A.right = [];
A.left = [];
for s=1:length(dataPaths)
    load(fullfile(dataPaths{s},'audiogram.mat'));
    A.right = [A.right; audiogram.right];
    A.left = [A.left; audiogram.left];    
end

%manually entered audiogram.right = [5 values];audiogram.left = [5 values];
%and saved as audiogram.mat for each subject ...any way to automate this?
frequency = [250 500 1000 2000 4000];
% A = {audiogram.right, audiogram.left};
T = {'Right Audiogram', 'Left Audiogram'};
M = {'r-o', 'b-x'};
key = {'right','left'};

figure;
for i = 1:2
    Amean = mean(A.(key{i}),1);
    Aerr = std(A.(key{i}),0,1)/sqrt(length(dataPaths));
    
    subplot(1,2,i)
    if all(Aerr==0)
        plot(frequency,Amean,M{i},'MarkerSize',8)
    else
        errorbar(frequency,Amean,Aerr,M{i},'MarkerSize',8);
    end
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