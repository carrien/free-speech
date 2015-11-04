function [h] = plot_vowels_centerVperiph(fmtdata,ntile)
%PLOT_VOWELS_CENTERVPERIPH  Plot vowel spread, highlighting center and periphery.
%   PLOT_VOWELS_CENTERVPERIPH(FMTDATA) plots

if nargin < 2 || isempty(ntile), ntile = 4; end

vowels = fieldnames(fmtdata.mels);

h = figure;
for v=1:length(vowels)
    plot(fmtdata.mels.(vowels{v}).first50ms.rawavg.f1,fmtdata.mels.(vowels{v}).first50ms.rawavg.f2,'k.')
    hold on;
    quantiles = quantile(fmtdata.mels.(vowels{v}).first50ms.dist,ntile);
    cen = fmtdata.mels.(vowels{v}).first50ms.dist < quantiles(1); % or meddist
    pph = fmtdata.mels.(vowels{v}).first50ms.dist > quantiles(end);
    plot(fmtdata.mels.(vowels{v}).first50ms.rawavg.f1(cen),fmtdata.mels.(vowels{v}).first50ms.rawavg.f2(cen),'g.')
    plot(fmtdata.mels.(vowels{v}).first50ms.rawavg.f1(pph),fmtdata.mels.(vowels{v}).first50ms.rawavg.f2(pph),'r.')
end

axis square
xlabel('F1 (mels)')
ylabel('F2 (mels)')