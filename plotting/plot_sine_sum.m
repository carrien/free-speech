function [sinewaves,t] = plot_sine_sum(freqs,amps,phaseoffsets,dur,fs,timeUnits,timeOffset,bPlotSep)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

nsines = length(freqs);

if nargin < 2 || isempty(amps)
    amps = ones(1,nsines);
elseif length(amps) ~= nsines
    amps = amps(1)*ones(1,nsines);
end
if nargin < 3 || isempty(phaseoffsets)
    phaseoffsets = zeros(1,nsines);
elseif length(phaseoffsets) ~= nsines
    phaseoffsets = phaseoffsets(1)*ones(1,nsines);
end
if nargin < 4 || isempty(dur)
    if nsines >= 2
        dur = 2/gcd(freqs(1),freqs(2));
    else
        dur = 2/freqs(1);
    end
end
if nargin < 5 || isempty(fs), fs = 11025; end
if nargin < 6 || isempty(timeUnits), timeUnits = 's'; end
if nargin < 7 || isempty(timeOffset), timeOffset = 0; end
if nargin < 8 || isempty(bPlotSep), bPlotSep = 1; end

linestyles = {'--',':','-.'};

%% plot overlay
figure;
sinewaves = zeros(nsines,floor(dur*fs)+1);
h_sin = gobjects(1,nsines);
for s=1:nsines
    [sinewaves(s,:),t] = get_sine(freqs(s),amps(s),phaseoffsets(s),dur,fs,timeUnits,timeOffset);
    linestyle = linestyles{mod(s-1,length(linestyles))+1};
    h_sin(s) = plot(t,sinewaves(s,:),'LineWidth',2,'LineStyle',linestyle);
    hold on;
end
h_sum = plot(t,sum(sinewaves),'Color','k','LineWidth',4);
strs = arrayfun(@num2str, freqs, 'Uniform', false);
strs{end+1} = 'sum';
legend(strs,'AutoUpdate','off');
hline(0,'k');
xlabel(sprintf('time (%s)',timeUnits))
ylabel('amplitude')
%uistack(h_sum,'bottom');
makeFig4Screen;
set(gcf,'Position',[100 50 1400 800]);
grid on;
ylims = get(gca,'YLim');

set(gcf,'Position',[870.3333   79.0000  816.0000  502.6667])

%% plot in separate subplots
if bPlotSep
    figure('Position',[100 50 1400 800]);
    tiledlayout(nsines+1,1)
    for s=1:nsines
        color = h_sin(s).Color;
        linewidth = h_sin(s).LineWidth;
        linestyle = h_sin(s).LineStyle;
        
        ax = nexttile;
        plot(t,sinewaves(s,:),'Color',color,'LineWidth',linewidth,'LineStyle',linestyle);
        hold on;
        hline(0,'k');
        ylabel('amplitude')
        
        ylim(ylims);
        ax.XTickLabel = [];
        ax.YTickLabel{1} = [];
        grid on;
    end
    ax = nexttile;
    color = h_sum.Color;
    linewidth = h_sum.LineWidth;
    linestyle = h_sum.LineStyle;
    plot(t,sum(sinewaves),'Color',color,'LineWidth',linewidth,'LineStyle',linestyle);
    hold on;
    hline(0,'k');
    xlabel('time (s)')
    ylabel('amplitude')
    box off
    ylim(ylims);
    grid on;
    
    set(gcf,'Position',[100.3333   41.6667  820.6667  839.3333])
end


%%
% axdownshift = .03;
% if nsines == 2
%     axheight = .29;
% elseif nsines == 3
%     axheight = .215;
% else
%     axheight = .21;
% end
%
% figure;
% set(gcf,'Position',[100 50 1400 800]);
% ax = gobjects(1,nsines+1);
% for s=1:nsines
%     ax(s) = subplot(nsines+1,1,s);
%     color = h_sin(s).Color;
%     linewidth = h_sin(s).LineWidth;
%     linestyle = h_sin(s).LineStyle;
%     plot(t,sinewaves(s,:),'Color',color,'LineWidth',linewidth,'LineStyle',linestyle);
%     hold on;
%     hline(0,'k');
%     ylabel('amplitude')
%     %ax(c).XAxis.Visible = 'off';
%     ax(s).YLim = ylim;
%     ax(s).Position(2) = ax(s).Position(2) - axdownshift;
%     ax(s).Position(4) = axheight;
%     makeFig4Screen;
%     ax(s).XTickLabel = [];
%     ax(s).YTickLabel{1} = [];
%     grid on;
% end
% ax(nsines+1) = subplot(nsines+1,1,nsines+1);
% color = h_sum.Color;
% linewidth = h_sum.LineWidth;
% linestyle = h_sum.LineStyle;
% plot(t,sum(sinewaves),'Color',color,'LineWidth',linewidth,'LineStyle',linestyle);
% hold on;
% hline(0,'k');
% xlabel('time (s)')
% ylabel('amplitude')
% box off
% ax(nsines+1).YLim = ylim;
% ax(nsines+1).Position(2) = ax(nsines+1).Position(2) - axdownshift;
% ax(nsines+1).Position(4) = axheight;
% makeFig4Screen;
% grid on;
% 
% set(gcf,'Position',[100.3333   41.6667  820.6667  839.3333])
