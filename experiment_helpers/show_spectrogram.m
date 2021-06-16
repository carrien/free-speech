function show_spectrogram(varargin)
if nargin >= 2
    w = varargin{1};
    fs = varargin{2};
elseif nargin == 1
    wavfn = varargin{1};
    [w, fs] = audioread(wavfn);
else
    fprintf('Wrong number of input arguments\n');
    return
end
    

if isempty(fsic(varargin, 'noFig'))
    figure;
end

% RPK addition June 2021: option for specifying wide- or narrow-band spectrogram. Defaults to wide. Argument can be in any
% position after 2
if isempty(fsic(varargin, 'narrow')) %If narrow isn't specified, then do wide-band
    [s, f, t]=spectrogram(w, 128, 96, 1024, fs);
else % If it is, then do narrow
    [s, f, t]=spectrogram(w, 256, 192, 1024, fs);
end

imagesc(t, f, 10 * log10(abs(s))); hold on;
axis xy;
hold on;
set(gca, 'YLim', [f(1), f(end)]);

ylim = 4000;
if ~isempty(fsic(varargin, 'YLim'))
    ylim = varargin{fsic(varargin, 'YLim') + 1};
end
set(gca, 'YLim', [0, ylim]);
set(gca, 'XLim', [t(1), t(end)]);

colormap(flipud(gray));
min_vals = min(log10(abs(s)));
max_vals = max(log10(abs(s)));
caxis([min(min_vals(~isinf(min_vals)))-10 max(max_vals(~isinf(max_vals)))+10])


return