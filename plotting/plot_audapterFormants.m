function [h] = plot_audapterFormants(data,p)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2, p = struct; end

%% set params
p = set_missingField(p,'bSpec',1,0);
p = set_missingField(p,'nfft',4096,0);
p = set_missingField(p,'thresh_gray',.65,0);
p = set_missingField(p,'max_gray',1,0);    
p = set_missingField(p,'ms_frame',4,0);
p = set_missingField(p,'ms_frame_advance',0.8,0);
p = set_missingField(p,'fmtsColor','c',0);
p = set_missingField(p,'fmtsLineWidth',3,0);
p = set_missingField(p,'sfmtsColor','m',0);
p = set_missingField(p,'sfmtsLineWidth',1.5,0);
p = set_missingField(p,'bOutline',1,0);
p = set_missingField(p,'figpos',[35 700 2510 150],0);
p = set_missingField(p,'fmtCenColor','y',0);
p = set_missingField(p,'fmtCenLineWidth',1,0);
p = set_missingField(p,'fmtCenLineStyle','--',0);
fs = data(1).params.sr;
frameLen = data(1).params.frameLen;

%% plot
h = figure('Position',p.figpos);
for nax = 1:length(data)
    subplot(1,length(data),nax)
    hold on;
    
    % plot spectrogram
    if p.bSpec        
        y = my_preemph(data(nax).signalIn,0.95);
        nsamp_window = round(p.ms_frame*fs/1000);
        nsamp_frame_advance = round(p.ms_frame_advance*fs/1000);
        nsamp_overlap = nsamp_window - nsamp_frame_advance;
        [s, f, t]=spectrogram(y, nsamp_window, nsamp_overlap, p.nfft, fs);
        %[s, f, t]=spectrogram(y, 128, 96, 1024, fs);
        %[s, f, t]=spectrogram(y, 256, 192, 1024, fs);
        imagesc(t, f, 10 * log10(abs(s))); hold on;
        axis xy;
        if isfield(p,'ylim')
            set(gca, 'YLim', [0, p.ylim]);
        else
            set(gca, 'YLim', [f(1), f(end)]);
        end
        set(gca, 'XLim', [t(1), t(end)]);
        
        my_colormap('my_gray',1,p.thresh_gray,p.max_gray);
        %     colormap(flipud(gray));
        %     min_vals = min(log10(abs(s)));
        %     max_vals = max(log10(abs(s)));
        %     caxis([min(min_vals(~isinf(min_vals)))-10 max(max_vals(~isinf(max_vals)))+10])
    end
    
    % plot formants
    zs = ~data(nax).fmts(:,1);
    data(nax).fmts(zs,:) = NaN;
    data(nax).sfmts(zs,:) = NaN;
    tAxis = 0 : frameLen : frameLen * (size(data(nax).fmts, 1) - 1);
    if isfield(p,'fmtCen')
        plot(tAxis/fs,repmat(p.fmtCen,length(tAxis),1),'LineStyle',p.fmtCenLineStyle,'Color',p.fmtCenColor,'LineWidth',p.fmtCenLineWidth)
    end
    if p.bOutline
        plot(tAxis/fs,data(nax).fmts(:, 1 : 2), 'Color','w','LineWidth',p.fmtsLineWidth+.5);
        plot(tAxis/fs,data(nax).sfmts(:, 1 : 2), 'Color','w','LineWidth',p.sfmtsLineWidth+.5);
    end
    plot(tAxis/fs,data(nax).fmts(:, 1 : 2), 'Color',p.fmtsColor,'LineWidth',p.fmtsLineWidth);
    plot(tAxis/fs,data(nax).sfmts(:, 1 : 2), 'Color',p.sfmtsColor,'LineWidth',p.sfmtsLineWidth);
    

    
    xlabel('time (s)')
    ylabel('frequency (Hz)')
    
end
