function [onset_bad, offset_bad] = validate_onsetOffset(dataPath, badThresh)
% Plots histograms of trials from a data.mat. Shows voice onset and offset
%   relative to trial onset and offset. Used to validate that we're capturing
%   the full utterance.
%
% 2021-03 CWN initial commit

% input argument validation
if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(badThresh), badThresh = 0.1; end


load(fullfile(dataPath, 'data.mat'), 'data');

% get length of an Audapter frame, in seconds
frameDur = data(1).params.frameLen / data(1).params.sRate; 

%preallocate
onset  = zeros(1, length(data));
offset = zeros(1, length(data));

% for testing purposes
data(1).fmts = zeros(985, 4);

% find onsets and offsets
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

% plot histograms
subplot(1, 2, 1)
histogram(onset, 'BinWidth', 0.05);
title('Onset distance to beginning');

subplot(1, 2, 2)
histogram(offset, 'BinWidth', 0.05);
title('Offset distance to end');

% collect trials too close to the edge
badThresh_onset  = badThresh;   %default 100 ms
badThresh_offset = badThresh;   %default 100 ms

onset_bad = find(onset <= badThresh_onset);
offset_bad = find(offset <= badThresh_offset);


end