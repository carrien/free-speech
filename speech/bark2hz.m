function [hz] = bark2hz(bark)
% Converts frequency in Hz to the Bark scale.

hz = 600 * sinh(bark/6);
