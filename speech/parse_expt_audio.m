function [ ] = parse_expt_audio(dataPath,sampleOffset)
%PARSE_EXPT_AUDIO  Create data trial struct from experiment wave file.
%   PARSE_EXPT_AUDIO(DATAPATH) uses the logfile found in DATAPATH to parse
%   individual trials from a whole-experiment audio file and save them

if nargin < 2, sampleOffset = []; end

savefile = fullfile(dataPath,'data.mat');
logfile = fullfile(dataPath,'exptlog.mat');
if ~exist(logfile,'file')
    fprintf('Converting logfile from JSON to mat...\n')
    convert_logfile(dataPath);
end
fprintf('Loading logfile...\n')
load(logfile);
ntrials = length(exptlog);

% convert from ms to samples
fprintf('Loading expt wavfile...\n')
[y,fs]=audioread(fullfile(dataPath,'expt.wav')); % get sample rate
nsamps = length(y);
t_ms = [exptlog(1:ntrials).t]; % stim times in ms
t_samp = ceil(t_ms*fs/1000);   % in samples
if isempty(sampleOffset)
    sampleOffset = 0; % find it programmatically here
end
t_samp = t_samp + sampleOffset;
if t_samp(end) > nsamps
    error('Error: requested sample %d of %d',t_samp(end),nsamps);
end

data = struct([]);
for i=1:ntrials
    startSamp = t_samp(i);
    if i+1 <= length(t_samp)
        endSamp = t_samp(i+1);
    else endSamp = nsamps;
    end
    [y,fs] = audioread(fullfile(dataPath,'expt.wav'),[startSamp endSamp]);
    new_fs = 11025;
    y = resample(y,new_fs,fs);
    data(i).signalIn = y;
    data(i).params.fs = new_fs;
end

fprintf('Saving parsed, downsampled data in %s\n',savefile)
save(savefile,'data')

end