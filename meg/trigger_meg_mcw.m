function [ ] = trigger_meg_mcw(obj,address,trig2send)
%TRIGGER_MEG_MCW  Send a trigger to the DAQ.

if nargin < 3 || isempty(trig2send), trig2send = 1; end

trigger_meg_mcw(obj,address,trig2send); % send trigger
pause(.05);
trigger_meg_mcw(obj,address,0);         % clear