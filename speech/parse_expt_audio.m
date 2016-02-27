function [data] = parse_expt_audio(dataPath,subjPrefix,sampleOffset)
%PARSE_EXPT_AUDIO  Create data trial struct from experiment wave file.
%   PARSE_EXPT_AUDIO(DATAPATH) uses the logfile found in DATAPATH to parse
%   individual trials from a whole-experiment audio file and save them

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(subjPrefix)
    if exist(fullfile(dataPath,'subjInfo.mat'),'file')
        load(fullfile(dataPath,'subjInfo.mat'))
        subjPrefix = sprintf('%s_',subjInfo.code);
    else subjPrefix = [];
    end
end
if nargin < 3, sampleOffset = []; end

wavfile = fullfile(dataPath,sprintf('%sexpt.wav',subjPrefix));
savefile = fullfile(dataPath,'data.mat');
logfile = fullfile(dataPath,'exptlog.mat');
if ~exist(logfile,'file')
    fprintf('Converting logfile from JSON to mat...\n')
    convert_logfile(dataPath);
end
fprintf('Loading logfile... ')
load(logfile);
fprintf('Done.\n')
ntrials = length(exptlog);

% convert from ms to samples
fprintf('Loading expt wavfile... ')
[y,fs]=audioread(wavfile); % get sample rate
fprintf('Done.\n')
nsamps = length(y);
stim_ms = [exptlog.startTime];  % stim times in ms
stim_samp = ceil(stim_ms*fs/1000);         % in samples
utt_ms = [exptlog.uttStartTime]; % utt times in ms
utt_samp = ceil(utt_ms*fs/1000);           % in samples
dur_ms = [exptlog.uttDuration];  % utt durs in ms
dur_samp = ceil(dur_ms*fs/1000);           % in samples
preUttBuffer_ms = 500;
preUttBuffer_samp = ceil(preUttBuffer_ms*fs/1000);           % in samples
postUttBuffer_ms = 500;
postUttBuffer_samp = ceil(postUttBuffer_ms*fs/1000);           % in samples

if isempty(sampleOffset) % find it programmatically here
%     % build filter to convolve
%     for i=1:length(exptlog)
%         uttStartSamp = ceil(exptlog(i).uttStartTime*fs/1000);
%         uttDurSamp = ceil(exptlog(i).uttDuration*fs/1000);
%         uttFilt(uttStartSamp:uttStartSamp+uttDurSamp) = 1;
%     end
%     % downsample to make conv tractable
%     y_ds = downsample(y,16);
%     uttFilt_ds = downsample(uttFilt,16);
%     % find the max of the convolution with amplitude
%     y_rms = get_sig_ampl(y_ds,fs);
%     C = conv(uttFilt_ds,y_rms);
%     [~,sampleOffset] = max(C);
    sampleOffset = 0;
end

% plot to check wav-logfile alignment
dsfact = 500; % downsample factor
y_ksamps = downsample(y,dsfact);
hksamps2plot = 10000;
figure;
plot(y_ksamps(1:hksamps2plot)); hold on;
ss = find(utt_samp/dsfact+dur_samp/dsfact+sampleOffset/dsfact<hksamps2plot);
if isempty(ss)
    ss = find(stim_samp/dsfact+sampleOffset/dsfact<hksamps2plot);
end
ss = ss(end)+1;
for s=1:ss
    if ~isempty(utt_samp)
        thisUtt = utt_samp(s)/dsfact+sampleOffset/dsfact:utt_samp(s)/dsfact+dur_samp(s)/dsfact+sampleOffset/dsfact;
        plot_filled_err(thisUtt,zeros(1,length(thisUtt)),max(abs(y_ksamps(1:hksamps2plot))),[],.2);
        thisUttPlus = utt_samp(s)/dsfact+sampleOffset/dsfact-preUttBuffer_samp/dsfact:utt_samp(s)/dsfact+dur_samp(s)/dsfact+sampleOffset/dsfact+postUttBuffer_samp/dsfact;
        plot_filled_err(thisUttPlus,zeros(1,length(thisUttPlus)),max(abs(y_ksamps(1:hksamps2plot))),[],.2);
    else
        vline(stim_samp(s)/dsfact-preUttBuffer_samp/dsfact+sampleOffset/dsfact,'r');
    end
end

stim_samp = stim_samp + sampleOffset;
utt_samp = utt_samp + sampleOffset;

% make sure trial markers aren't negative or longer than the signal
if stim_samp(1) < 0
    error('Sample indices cannot be negative. Try increasing the sample offset (%d) or making it positive.',sampleOffset);
elseif stim_samp(end) > nsamps || (~isempty(utt_samp) && utt_samp(end) + dur_samp(end) + postUttBuffer_samp > nsamps)
    error('Requested sample %d of %d',utt_samp(end) + dur_samp(end) + postUttBuffer_samp, nsamps);
end

data = struct([]);
for itrial=1:ntrials
    fprintf('')
    if ~isempty(utt_samp)
        startSamp = utt_samp(itrial) - preUttBuffer_samp;
        endSamp = utt_samp(itrial) + dur_samp(itrial) + postUttBuffer_samp;
    else
        startSamp = stim_samp(itrial);
        if itrial<length(stim_samp)
            endSamp = stim_samp(itrial+1);
        else
            endSamp = stim_samp(itrial)+fs*2; % if final trial, take 2 seconds
        end
    end
    [y,fs] = audioread(wavfile,[startSamp endSamp]);
    new_fs = 11025;
    y = resample(y,new_fs,fs);
    data(itrial).signalIn = y;
    data(itrial).params.fs = new_fs;
end

fprintf('Parsed and downsampled %d trials to %s\n',length(data),savefile)
save(savefile,'data')

end