function [onset_bad, offset_bad] = validate_onsetOffset(dataPath, badThresh)
% Plots histograms of trials from a data.mat. Shows voice onset and offset
%   relative to trial onset and offset. Used to validate that we're capturing
%   the full utterance.
%
%   Returns up to two arguments. Each is a vector of trial numbers which
%   are within `badThresh` seconds of the edge of the recording. The first
%   is when the onset is too close to the beginning; the second is when the
%   offset is too close to the end.
%
% 2021-03 CWN initial commit

% input argument validation
if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(badThresh), badThresh = 0.1; end %default 100 ms


load(fullfile(dataPath, 'data.mat'), 'data');

% get length of an Audapter frame, in seconds
frameDur = data(1).params.frameLen / data(1).params.sRate; 

%preallocate
onset  = zeros(1, length(data));
offset = zeros(1, length(data));

% find onsets and offsets, defined using data.fmts
for i = 1:length(data)
    on = find(data(i).fmts(:, 1), 1, 'first') * frameDur;
    if ~isempty(on)
        onset(i)  = on;
    end %else, leave it as zero
    
    trialLen = length(data(i).fmts) * frameDur;
    off = trialLen - find(data(i).fmts(:, 1), 1, 'last')  * frameDur;
    if ~isempty(off)
        offset(i)  = off;
    end
end

% prep for histograms
binSize = 0.1;
maxOnsetBin = ceil(max(onset)/binSize)*binSize;
maxOffsetBin = ceil(max(offset)/binSize)*binSize;

% plot histograms
figure;
subplot(1, 2, 1)
%histogram(onset, 'BinWidth', 0.1);
histogram(onset, 'BinEdges', 0 : binSize : maxOnsetBin);
title('Onset distance to beginning');
ylabel('Number of trials')
xlabel('Time (seconds)')

subplot(1, 2, 2)
%histogram(offset, 'BinWidth', 0.1);
histogram(offset, 'BinEdges', 0 : binSize : maxOffsetBin);
title('Offset distance to end');
xlabel('Time (seconds)')

% collect trials too close to the edge
badThresh_onset  = badThresh;   
badThresh_offset = badThresh;   

onset_bad = find(onset <= badThresh_onset);
offset_bad = find(offset <= badThresh_offset);



end