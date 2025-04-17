function [h_layout,subh_layout] = plot_audapterFormants(data, p, bInterpret, parent_handle, p_layout)
% Provides a quick plot of the waveform, spectrogram, and signalIn formants
%   (fmts) and signalOut formants (sfmts) for trial data. Used for
%   spot-checking a couple trials.
%
% IN:
%   data: The data struct to view data from. Note that the output
%     looks best when viewing 1-5 trials at a time. Consider passing in data
%     as `data(1:4)`. Required.
%   p: Struct of parameters to use when plotting. Default: [see code].
%   bInterpret: A binary flag for whether or not to print information which
%     may help you interpret your results. Default: 1.
%
% Other validation functions at: https://kb.wisc.edu/smng/109809

% TODO make it respect the figpos input argument again
% TODO update header

if nargin < 2, p = struct; end
if nargin < 3 || isempty(bInterpret), bInterpret = 1; end

if length(data) > 50
    error(['Data file too long. Choose a subset of fewer than 50 trials ' ...
        '(ideally 2 to 10 trials) to view at one time.']);
end

screenSize = get(0,'ScreenSize');

%% set params
p = set_missingField(p,'bWave',1,0);
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
p = set_missingField(p,'figpos',[10 700 screenSize(3)-20 175],0);
p = set_missingField(p,'fmtCenColor','y',0);
p = set_missingField(p,'fmtCenLineWidth',1,0);
p = set_missingField(p,'fmtCenLineStyle','--',0);
fs = data(1).params.sr;
frameLen = data(1).params.frameLen;

%% plotting setup

if p.bWave
    nrows = 3;
else
    nrows = 1;
end
ncols = length(data);

% preallocate handles for tiles in layout
subh_layout = gobjects(1,ncols); 

% create tiled layout, either from scratch or as a child of a parent TiledChartLayout
if nargin < 4 || isempty(parent_handle)
    figure;
    h_layout = tiledlayout(nrows, ncols);
else
    h_layout = tiledlayout(parent_handle, nrows, ncols);
end

% apply each parameter in p_layout to the new layout
if nargin < 5 || ~isempty(p_layout)
    layout_properties = fields(p_layout);
    for i = 1:length(layout_properties)
        h_layout.Layout.(layout_properties{i}) = p_layout.(layout_properties{i});
    end
end

%% plot
for trial_ix = 1:ncols
    subh_layout(trial_ix) = nexttile(h_layout, [1 1]);
    hold on;
    
    if p.bWave
        % plot waveform
        plot(data(trial_ix).signalIn, 'Color','k');
        ymax = .25; %max(abs(data(nax).signalIn));
        axis tight;
        set(gca,'YLim',[-ymax ymax]);
        set(gca,'XColor','none');
        set(gca,'YColor','none');

        % set current axis to be a span of the bottom two rows of the
        % current column. (Current column num = tile_ix)
        nexttile(trial_ix + ncols, [2, 1])
        hold on;
    end
    
    % plot spectrogram
    if p.bSpec        
        y = my_preemph(data(trial_ix).signalIn,0.95);
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
        %colormap(flipud(gray));
        %min_vals = min(log10(abs(s)));
        %max_vals = max(log10(abs(s)));
        %caxis([min(min_vals(~isinf(min_vals)))-10 max(max_vals(~isinf(max_vals)))+10])
    end
    
    % plot formants
    zs = ~data(trial_ix).fmts(:,1);
    data(trial_ix).fmts(zs,:) = NaN;
    data(trial_ix).sfmts(zs,:) = NaN;
    tAxis = 0 : frameLen : frameLen * (size(data(trial_ix).fmts, 1) - 1);
    if isfield(p,'fmtCen')
        plot(tAxis/fs,repmat(p.fmtCen,length(tAxis),1),'LineStyle',p.fmtCenLineStyle,'Color',p.fmtCenColor,'LineWidth',p.fmtCenLineWidth)
    end
    if p.bOutline
        plot(tAxis/fs,data(trial_ix).fmts(:, 1 : 2), 'Color','w','LineWidth',p.fmtsLineWidth+.5);
        plot(tAxis/fs,data(trial_ix).sfmts(:, 1 : 2), 'Color','w','LineWidth',p.sfmtsLineWidth+.5);
    end
    plot(tAxis/fs,data(trial_ix).fmts(:, 1 : 2), 'Color',p.fmtsColor,'LineWidth',p.fmtsLineWidth);
    plot(tAxis/fs,data(trial_ix).sfmts(:, 1 : 2), 'Color',p.sfmtsColor,'LineWidth',p.sfmtsLineWidth);
    

    
    xlabel('time (s)')    
    if trial_ix==1
        ylabel('frequency (Hz)')
    else
        set(gca, 'YTickLabel', '');
    end
    
end


if bInterpret
    fprintf(['\nSimply displays the wave form (top), spectrogram (bottom), signalIn\n' ...
        ' formant track (bottom; cyan), and signalOut formant track (bottom; magenta).\n' ...
        ' This tool is useful for spot-checking formant tracks and basic duration info.\n\n']);
    fprintf('Set input argument bInterpret == 0 to stop seeing this message.\n\n');
end


end