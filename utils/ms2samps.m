function [samps] = ms2samps(ms,fs)
%MS2SAMPS  Convert from milliseconds to samples given sampling rate.

samps = round(fs*ms/1000)+1; % add one for one-indexing