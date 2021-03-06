function [h_fig] = setup_exptFigs()
%SETUP_EXPTFIGS  Creates figures for experimenter and participant.
%   SETUP_EXPTFIGS() creates and returns handles to figures for:
%   (1) displaying stimuli to the participant (monitor 2)
%   (2) displaying status and formant tracks for experimenter (monitor 1)
%   (3) displaying a copy of the participant's view for experimenter (monitor 1)

% set figure positions
get_figinds_audapter;
pos{stim} = [1 0 1 1];         % participant view
pos{ctrl} = [0.6 0.2 0.4 0.8]; % experimenter view and formant tracking
pos{dup} = [0 0.3 0.6 0.7];    % duplicate participant view for experimenter

% define figure attributes
figparams.Units = 'normalized';
figparams.MenuBar = 'none';
figparams.Color = 'black';

% create all windows
for i=1:length(pos)
    h_fig(i) = figure(figparams);
    set(h_fig(i),'OuterPosition',pos{i});
    axis square off
    xlim([0 1]);
    ylim([0 1]);
end

% set experimenter view to gray bg
set(h_fig(ctrl),'Color',[.75 .75 .75]);

end