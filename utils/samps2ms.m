function [ms] = samps2ms(samps,fs)
%MS2SAMPS  Convert from samples to milliseconds given sampling rate.

ms = samps/fs*1000;