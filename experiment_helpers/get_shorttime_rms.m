function [rmsdata] = get_shorttime_rms(data, fs, winsize)

% this function calculates rms over short windows, similar to Audapter's
% short-time rms function, and returns a vector of rms data
% data is, for example, data.signalIn
% fs is sample rate
% winsize is window size in s

rmsdata = [];
siglen = length(data);
chronlen = siglen/fs;
nWins = floor(chronlen/winsize); % number of calcs
nFrames = floor(siglen/nWins); % per rms calc


for r = 1:nWins
    startidx = ((r-1)*nFrames) + 1;
    endidx = startidx + nFrames -1;
    shortrms = rms(data(startidx:endidx));
    rmsdata(r) = shortrms;
end

rmsdata = rmsdata;