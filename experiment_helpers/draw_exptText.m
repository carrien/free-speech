function [h] = draw_exptText(h_fig,x,y,txt,varargin)

get_figinds_audapter;

% make stimulus window current
figure(h_fig(stim));
h = text(x,y,txt,varargin{:});
CloneFig(h_fig(stim),h_fig(dup))
