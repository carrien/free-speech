function [data] = resample_data(data,fs)
%RESAMPLE_DATA  Resamples a data.mat file to the specified rate.

if nargin < 2, fs = 11025; end

for i=1:length(data)
    y_rec = data(i).signalIn;
    fs_rec = data(i).params.fs;
    data(i).signalIn = resample(y_rec,fs,fs_rec);
    data(i).params.fs = fs;
end
