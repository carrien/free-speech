function [sinewaves,t] = plot_sine_sum(components,amps,phaseoffsets,dur,fs)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2 || isempty(amps) || length(amps) ~= length(components)
    amps = ones(1,length(components));
end
if nargin < 3 || isempty(phaseoffsets) || length(phaseoffsets) ~= length(components)
    phaseoffsets = zeros(1,length(components));
end
if nargin < 4 || isempty(dur)
    if length(components) >= 2
        dur = 2/gcd(components(1),components(2));
    else
        dur = 2/components(1);
    end
end
if nargin < 5 || isempty(fs), fs = 11025; end

linestyles = {'--',':','-.'};

figure;
for c=1:length(components)
    [s,t] = get_sine(components(c),dur,fs,phaseoffsets(c));
    sinewaves(c,:) = s*amps(c);
    linestyle = linestyles{mod(c-1,length(linestyles))+1};
    plot(t,sinewaves(c,:),'LineWidth',3,'LineStyle',linestyle);
    hold on;
end
h = plot(t,sum(sinewaves),'LineWidth',4);
strs = arrayfun(@num2str, components, 'Uniform', false);
strs{end+1} = 'sum';
legend(strs,'AutoUpdate','off');
hline(0,'k');
xlabel('time (s)')
ylabel('amplitude')
box off
uistack(h,'bottom');
makeFig4Screen;
set(gcf,'Position',[100 100 1400 800]);
grid on;