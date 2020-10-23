function [ ] = trigger_meg(di,trig2send,usetrigs)
%TRIGGER_MEG  Send a USB trigger
%   Detailed explanation goes here

if nargin < 2 || isempty(trig2send), trig2send = 1; end
if nargin < 3 || isempty(usetrigs), usetrigs = 1; end

if(usetrigs)
    DaqDOut(di,0,trig2send);  %send trigger
    DaqDOut(di,0,0);  %clear trig
end