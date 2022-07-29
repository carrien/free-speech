function [onset_bad, offset_bad] = validate_onsetOffset(dataPath, badThresh, bInterpret)
% Plots histograms of trials from a data.mat. Shows voice onset and offset
%   relative to trial onset and offset. Used to validate that we're capturing
%   the full utterance. Returns vectors of bad trials.
%
% INPUT ARGUMENTS:
%   dataPath. The file location of the expt.mat file to evaluate. Defaults
%     to the current directory.
%   badThresh. Threshold (in seconds) for how close a trial must be to the
%     edge to be considered bad (i.e., "too close")
%   bInterpret. Binary flag for if you want information printed to command
%     window about how to interpret your results. Defaults to 1 (print).
%
% OUTPUT ARGUMENTS:
%   onset_bad. Vector of indexes where the onset was within badThresh
%     seconds of the recording onset.
%   offset_bad. Same as onset_bad, but for offsets to close to the end edge.
%
% Other validation functions at: https://kb.wisc.edu/smng/109809

% 2021-03 CWN initial commit

% input argument validation
if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(badThresh), badThresh = 0.1; end %default 100 ms
if nargin < 3 || isempty(bInterpret), bInterpret = 1; end

fprintf('Loading data... ');
load(fullfile(dataPath, 'data.mat'), 'data');
fprintf('done.\n');

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
set(gca, 'xdir', 'reverse');
title('Offset distance to end');
xlabel('Time (seconds)')

% collect trials too close to the edge
badThresh_onset  = badThresh;   
badThresh_offset = badThresh;   

onset_bad = find(onset <= badThresh_onset);
offset_bad = find(offset <= badThresh_offset);


%% print interpretation to screen
if bInterpret
fprintf(['\n\n==========  How to interpret your results:  ==========\n' ...
    'For very basic info, read this function''s header. (run `help validate_onsetOffset`).\n\n']);

fprintf(['It''s normal for people to, on occasion, start talking too late in a trial.\n' ...
    ' When that happens, part of their utterance gets cut off. These trials will\n' ...
    ' show up in the offset_bad output argument. They will also show up near zero\n' ...
    ' (the right edge) in the Offset Distance to Edge figure. You''re probably OK\n' ...
    ' if 0-3%% of trials are "bad" in this way. If more than 5%% of trials have bad\n' ...
    ' offsets (get cut off at the end), consider lengthening expt.timing.stimdur.\n\n']);

fprintf(['It''s rarer, but still possible, for people to start talking BEFORE\n' ...
    ' the stimulus appears on screen. Maybe they get into a cadence of talking, which\n' ...
    ' is more likely if there are a small number of stimulus words. These trials\n' ...
    ' will show up in the onset_bad output argument. They will also show up near\n' ...
    ' zero (the left edge) in the Onset Distance to Beginning figure. No more than\n' ...
    ' 1% of trials should be like this.']);

fprintf(['Note that "false positives" can appear in either group due to random noise.\n' ...
    ' For example, if someone coughs at the end of the trial, that trial may get\n' ...
    ' put into the offset_bad group. The onset and offset in this function are\n' ...
    ' crudely measured and susceptible to mistakes.\n\n']);

fprintf(['Thus, if you have a bunch of trials in either group, you should manually\n' ...
    ' review those trials. You can do so with the `audioGUI` function. You can put\n' ...
    ' the results from onset_bad and offset_bad into audioGUI''s second input\n' ...
    ' argument to view those trials directly. Check to see if the person was\n' ...
    ' ACTUALLY talking at the very beginning/end of the trial, or if it was a\n' ...
    ' false positive. Recount the number of "bad" trials -- once you exclude\n' ...
    ' the false positives, you may have a much more reasonable number of "bad"\n' ...
    ' trials. If you had a LOT of false positives, then maybe sometimes was\n' ...
    ' bad about the recording environment. For example, if the microphone gain\n' ...
    ' was too high, you will pick up more background noise.\n\n']);
fprintf('Set input argument bInterpret == 0 to stop seeing this message.\n\n');
end

    
    
    
end