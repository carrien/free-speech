function [ ] = gen_wavs_from_datastruct(exptName,snum,subdir)
%GEN_WAVS_FROM_DATASTRUCT  Write wav files from mic (signalIn) data.
%   GEN_WAVS_FROM_DATASTRUCT(EXPTNAME,SNUM,SUBDIR)

if nargin < 3, subdir = []; end

dataPath = getAcoustSubjPath(exptName,snum,subdir);
load(fullfile(dataPath,'data.mat'));

if ~exist(fullfile(dataPath,'wavs'),'dir')
    mkdir(dataPath,'wavs');
end

maxint = 32767;

for i=1:length(data)
    sig = data(i).signalIn;
    sig = int16(sig.*(maxint/max(abs(sig))));
    fs = data(i).params.fs;
    wavfile = fullfile(dataPath,'wavs',sprintf('%03d.wav',i));
    wavwrite(sig,fs,wavfile);
end