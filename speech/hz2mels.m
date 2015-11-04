function mels = hz2mels(hertz)
% Converts frequency in Hz to the logarithmic mel scale.

mels = 1127.01048*log(1 + hertz/700);