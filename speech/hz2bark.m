function [bark] = hz2bark(hz)
% Converts frequency in Hz to the Bark scale.

bark = 26.81./(1+(1960./hz)) - 0.53;