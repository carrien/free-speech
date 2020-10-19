function [] = delete_exptText(h_fig,h_2delete)

delete(h_2delete);
get_figinds_audapter;
CloneFig(h_fig(stim),h_fig(dup))
