function [taxis] = get_taxis(tstep,length,startTime)
%GET_TAXIS  Return time axis matching signal length based on timestep.

if nargin < 3 || isempty(startTime), startTime = 0; end

taxis = startTime:tstep:startTime+(tstep*(length-1));