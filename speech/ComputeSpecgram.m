function [b,f] = ComputeSpecgram(s, sRate, specRes, doPremp)

if doPremp, s = diff(s); end;		% 1st difference if preemphasis
frame = 512;						% analysis frame
wSize = 6*specRes;					% analysis window (msecs)
shift = 1;							% window shift (msecs)
nSamps = length(s);
wSize = floor(wSize*sRate/1000);	% window size (samples)
wSize = wSize + mod(wSize,2);		% make sure it's even
shift = shift * sRate/1000;			% overlap (fractional samples)
nFrames = round(nSamps/shift);
w = hanning(wSize);
b = zeros(frame, nFrames);
sx = wSize/2 + 1;					% fractional sample index
s = [zeros(wSize/2,1) ; s ; zeros(wSize,1)];
for fi = 1 : nFrames,
    si = round(sx);
    pf = abs(fft(w .* s(si:si+wSize-1),frame*2));
    b(:,fi) = pf(2:frame+1);		% drop DC, upper reflection
    sx = sx + shift;
end;
b = filter(ones(3,1)/3,1,abs(b),[],2);	% clean holes
f = linspace(0,sRate/2,frame);