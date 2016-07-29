function [timewindows] = get_timewindows(eventTimes,pre,post)
%GET_TIMEWINDOWS  Create time windows around a list of events.
%   GET_TIMEWINDOWS(EVENTTIMES,PRE,POST)

timewindows(:,1) = eventTimes + pre;
timewindows(:,2) = eventTimes + post;