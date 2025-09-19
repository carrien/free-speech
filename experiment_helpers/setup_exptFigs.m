function [h_fig] = setup_exptFigs()
%SETUP_EXPTFIGS  Creates figures for experimenter and participant.
%   SETUP_EXPTFIGS() creates and returns handles to figures for:
%   (1) displaying stimuli to the participant (monitor 2)
%   (2) displaying status and formant tracks for experimenter (monitor 1)
%   (3) displaying a copy of the participant's view for experimenter (monitor 1)

% set figure positions
get_figinds_audapter;

% These are the baseline positions of each figure. The x position (first
% value) is adjusted later once we know where the monitors are.
pos{stim} = [0 0 1 1];         % stimulus presentation window. Displays on participant's monitor.
pos{ctrl} = [0.6 0.2 0.4 0.8]; % experimenter view and formant tracking. Displays on experimenter's monitor.
pos{dup} = [0 0.3 0.6 0.7];    % duplicate of 'stim' for monitoring. Displays on experimenter's monitor.

% Regardless of how the experimenter and participant's monitors are
% PHYSICALLY positioned (left vs right), this code assumes that in Windows
% display settings, the experimenter's screen is virtually positioned to
% the leftmost position, and the participant's screen is to the right of
% the experimenter's screen. The leftmost monitor's position will have the 
% smallest x position value. That x coordinate value may be 1, or it may be
% a negative number, depending on factors outside of your direct control.
%
% Each row in get(0, 'MonitorPositions') represents a monitor. Which row a
% monitor appears in is also outside of your direct control. Therefore, we
% have to do a lookup of the x position to determine which indexed monitor
% is the leftmost one. That will be set to the experimenter's monitor, and
% the next monitor to the right will be the participant's monitor's index.

monitorPositions = get(0, 'MonitorPositions');
nMonitors = height(monitorPositions);
if nMonitors > 1
    [~, sortedMonitorsIndices] = sort(monitorPositions);

    % get values for experimenter and participant monitors
    exptMon_ix = sortedMonitorsIndices(1);
    exptMon_xCoord = monitorPositions(exptMon_ix, 1);
    exptMon_xLength = monitorPositions(exptMon_ix, 3);
    ppMon_ix = sortedMonitorsIndices(2);
    ppMon_xCoord = monitorPositions(ppMon_ix, 1);
    ppMon_xLength = monitorPositions(ppMon_ix, 3);

    % adjust each figure's position depending on which monitor it's
    % supposed to display on.
    exptMon_relativePos = round((exptMon_xCoord-1) / exptMon_xLength);
    pos{ctrl}(1) = pos{ctrl}(1) + exptMon_relativePos;
    pos{dup}(1)  = pos{dup}(1)  + exptMon_relativePos;

    ppMon_relativePos = round((ppMon_xCoord-1) / ppMon_xLength);
    pos{stim}(1) = pos{stim}(1) + ppMon_relativePos;
end
    

%     monitor1_xCoordinate = monitorPositions(1,1);
%     monitor2_xCoordinate = monitorPositions(2,1);
%     mon2LeftOfMon1 = monitor2_xCoordinate < monitor1_xCoordinate;
%     if mon2LeftOfMon1
%         pos{stim} = [-1 0 1 1];         % participant view on left screen
%     else
%         pos{stim} = [1 0 1 1];         % participant view on right screen
%     end
% else %1 monitor setup
%     pos{stim} = [1 0 1 1];
% end
% 
% pos{ctrl} = [0.6 0.2 0.4 0.8]; % experimenter view and formant tracking
% pos{dup} = [0 0.3 0.6 0.7];    % duplicate participant view for experimenter

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

% set stim full screen
set(h_fig(stim),'WindowState','fullscreen');

end