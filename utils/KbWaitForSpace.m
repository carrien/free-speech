function [ ] = KbWaitForSpace(timelimit)
%KBWAITFORSPACE  Wait until spacebar is pressed.

if nargin < 1 || isempty(timelimit), timelimit = inf; end

KbWaitForKey(32,timelimit);
