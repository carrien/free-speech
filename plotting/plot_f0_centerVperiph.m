function [h] = plot_f0_centerVperiph(f0data,ntile,targets)
%PLOT_F0_CENTERVPERIPH  Plot f0 spread, highlighting center and periphery.
%   PLOT_F0_CENTERVPERIPH(F0DATA)

if nargin < 2 || isempty(ntile), ntile = 4; end
if nargin < 2 || isempty(targets), targets = [174.6141 195.9977 220.0000]; end

pitches = fieldnames(f0data.mels);

h = figure;
for v=1:length(pitches)
    plot(targets(v),f0data.mels.(pitches{v}).first50ms.rawavg.f0,'k.')
    hold on;
    quantiles = quantile(f0data.mels.(pitches{v}).first50ms.dist,ntile);
    cen = f0data.mels.(pitches{v}).first50ms.dist < quantiles(1); % or meddist
    pph = f0data.mels.(pitches{v}).first50ms.dist > quantiles(end);
    plot(targets(v),f0data.mels.(pitches{v}).first50ms.rawavg.f0(cen),'g.')
    plot(targets(v),f0data.mels.(pitches{v}).first50ms.rawavg.f0(pph),'r.')
end

axis square
xlabel('target F0 (mels)')
ylabel('produced F0 (mels)')

% temp for poster
axis([235 325 200 325])
set(gca,'XTick',250:25:325)
set(gca,'YTick',200:25:325)
box off