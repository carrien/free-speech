function [] = subplot_expt_spectrogram(data, p, h_fig, h_sub)
%SUBPLOT_EXPT_SPECTROGRAM: function for displaying and properly clearing
% spectrograms from experimenter view in various experiements that use Audapter.
%
% SUBPLOT_SPECTROGRAM(DATA, FIGS, P) 
%
%                   data: variable from AudapterIO('getData'), used by
%                   show_spectrogram.
%                   h_fig / h_sub: figure handles 
%                   p: parameter variable for Audapter

get_figinds_audapter;

figure(h_fig(ctrl))
subplot(h_sub(2))
        
cla(h_sub(2));

show_spectrogram(data.signalIn, data.params.sr, 'noFig');
tAxis = 0 : p.frameLen : p.frameLen * (size(data.fmts, 1) - 1);
plot(tAxis/data.params.sr,data.fmts(:, 1 : 2), 'c','LineWidth',3);
plot(tAxis/data.params.sr,data.sfmts(:, 1 : 2), 'm','LineWidth',1.5);



end