function [] = filter_audiodata(dataPath)
%FILTER_DATA  Apply filter to speech data.

bSave = savecheck(fullfile(dataPath,'data.mat'));
if ~bSave, return; end

% load data
load(fullfile(dataPath,'data.mat'),'data');
load(fullfile(dataPath,'expt.mat'),'expt');

fs = data(1).params.fs; % assume constant sampling rate

a.i = [.25 1 .5 0];
a.E = [.25 1 .5 0];
a.ae = [.2 1 .5 0];

f.i = [0 1950/(fs/2) 2200/(fs/2) .9];
f.E = [0 1700/(fs/2) 1950/(fs/2) .9];
f.ae = [0 1600/(fs/2) 1850/(fs/2) .9];

for itrial = 1:length(data)
    y = data(itrial).signalIn;
    
    if strcmp(expt.listVowels{itrial},'i')
        fr = f.i;
        amp = a.i;
    elseif strcmp(expt.listVowels{itrial},'E')
        fr = f.E;
        amp = a.E;
    elseif strcmp(expt.listVowels{itrial},'ae')
        fr = f.ae;
        amp = a.ae;
    end
    
    n = 17;
    b = firpm(n,fr,amp);
    data(itrial).signalIn = filter(b,1,y);
end

save(fullfile(dataPath,'data.mat'),'data');
save(fullfile(dataPath,'filtcoeffs.mat'),'a','f','n','b');
