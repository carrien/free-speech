function hertz = mels2hz(mels)
% Converts frequency on the mel scale to Hertz.

hertz = 700*(exp(mels/1127.01048)-1);