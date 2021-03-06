function [h_dur,success] = plot_duration_feedback_bar(h_fig, data, params,bPtb)
%add duration feedback to display for auditory compensation study. Inputs:
%   h_fig:          figure handle for plot
%   data:           Audapter data file for a single trial
%   params:         paramater struct including the following fields:
%      min_dur:     minimum allowable vowel duration (in s), default 0.25
%      min_dur:     maximum allowable vowel duration (in s), default 0.5
%      ons_thresh:  percentage of maximum amplitude for onset threshold
%                   (0-1), default 0.1
%      offs_thresh: percentage of maximum amplitude for offset threshold
%                   (0-1), default 0.4

if nargin < 3 || isempty(params), params = []; end
if nargin < 4 || isempty(bPtb), bPtb = 0; end

%default duration tracking parameters
if ~isfield(params,'offs_thresh')
    params.offs_thresh = 0.4;
end
if ~isfield(params,'ons_thresh')
    params.ons_thresh = 0.3;
end
if ~isfield(params,'max_dur')
    params.max_dur = 0.5;
end
if ~isfield(params,'min_dur')
    params.min_dur = 0.25;
end
% if ~isfield(params, 'circ_pos')
%     params.circ_pos = [.45,.15,.1,.1];%define location and size of circle
% end
%get amplitude data from Audapter data structure

if ~bPtb
    ampl = data.rms(:,1);
else
    ampl = data.rmsdata;    
    if ~isfield(params,'offs_thresh')
    params.offs_thresh = 0.35;
    end
    if ~isfield(params,'ons_thresh')
    params.ons_thresh = 0.25;
    end
end

%find maximum amplitude
    [max_a,imax] = max(ampl);


%find first point above amplitude threshold
above_thresh = find(ampl>max_a*params.ons_thresh);
if ~isempty(above_thresh)
    onset = above_thresh(1);
else
    onset = [];
end

%find first point after amplitude max below amplitude threshold
below_thresh = find(ampl(imax:end)<max_a*params.offs_thresh);
if ~isempty(below_thresh)
    offset = below_thresh(1)+imax;
else
    offset = [];
end

%find vowel duration in frames. Using the same variable name for ptb expts,
%  but remember that rms is in windows of length winsize. This should be
%  10-ms windows.
if ~isempty(offset) && ~isempty(onset)
    vowel_dur_frames = offset-onset;
else
    vowel_dur_frames = 0;
end

%convert from frames to s

if ~bPtb
    vowel_dur = vowel_dur_frames*data.params.frameLen/data.params.sr;
else
    vowel_dur = vowel_dur_frames*data.winsize;
end
%plot feedback
%figure(h_fig)

% if vowel_dur <= params.max_dur && vowel_dur >= params.min_dur
%     h_dur(1) = rectangle('Position',params.circ_pos,'Curvature',[1,1],'Facecolor', 'g');
%     success = 1;
% elseif vowel_dur > params.max_dur
%     h_dur(1) = rectangle('Position',params.circ_pos,'Curvature',[1,1],'Facecolor', 'y');
%     h_dur(2) = text(params.circ_pos(1)+0.05,params.circ_pos(2)-0.05,{'Speak a little faster'}, 'Color', 'y', 'FontSize', 30,'HorizontalAlignment','Center');
%     success = 0;
% elseif vowel_dur < params.min_dur
%     h_dur(1) = rectangle('Position',params.circ_pos,'Curvature',[1,1],'Facecolor', 'b');
%     h_dur(2) = text(params.circ_pos(1)+0.05,params.circ_pos(2)-0.05,{'Speak a little more slowly'}, 'Color', 'b', 'FontSize', 30,'HorizontalAlignment','Center');
%     success = 0;
% end



if vowel_dur <= params.max_dur && vowel_dur >= params.min_dur
    success = 1;
else
    success = 0;
end

if ~bPtb
    h_dur = draw_durFB_bar(h_fig,vowel_dur,params);
else
    h_dur = [];
    draw_durFB_bar_ptb(h_fig,vowel_dur,params);
end
