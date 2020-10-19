function [h_ampl,success] = plot_amplitude_feedback(h_fig, rmsdata, params, bPtb)
%add duration feedback to display for auditory compensation study. Inputs:
%   h_fig:          figure handle for plot
%   data:           Audapter data file for a single trial
%   params:         paramater struct including the following fields:
%      min_ampl:     minimum allowable average amplitude, default 0.1
%      max_ampl:     maximum allowable average amplitude, default 0.15
%      ons_thresh:  percentage of maximum amplitude for onset threshold
%                   (0-1), default 0.1
%      offs_thresh: percentage of maximum amplitude for offset threshold
%                   (0-1), default 0.4

%h_fig is 'win' for ptb expts

if nargin < 3 || isempty(params), params = []; end
if nargin < 4 || isempty(bPtb), bPtb = 0; end

%default duration tracking parameters
if ~isfield(params,'offs_thresh')
    params.offs_thresh = 0.4;
end
if ~isfield(params,'ons_thresh')
    params.ons_thresh = 0.3;
end
if ~isfield(params,'min_ampl')
    params.min_ampl = 0.1;
end
if ~isfield(params,'max_ampl')
    params.max_ampl = 0.15;
end
if ~isfield(params, 'circ_pos')
    params.circ_pos = [.45,.15,.1,.1];%define location and size of circle
end

% if ~bPtb
%     %get amplitude data from Audapter data structure
%     rmsdata = data.rms(:,1);
%     
%     %find maximum amplitude
% else
%     
%     if ~isfield(params,'fs')
%         params.fs = 44100;
%     end
%     rmsdata = get_shorttime_rms(data, params.fs, 0.01)
%     if ~isfield(params,'max_ampl')
%         params.max_ampl = 0.1750;
%     end
%     if ~isfield(params,'min_ampl')
%         params.min_ampl = 0.1250;
%     end
% end

[currAmp,imax] = max(rmsdata);

% %find first point above amplitude threshold
% above_thresh = find(rmsdata>max_rms*params.ons_thresh);
% onset = above_thresh(1);
%
% %find first point after amplitude max below amplitude threshold
% below_thresh = find(rmsdata(imax:end)<max_rms*params.offs_thresh);
% if ~isempty(below_thresh)
%     offset = below_thresh(1)+imax;
% else
%     offset = [];
% end
%
% %find average amplitude between onset and offset
% if ~isempty(offset) && ~isempty(onset)
%     vowel_ampl = nanmean(rmsdata(onset:offset));
% elseif ~isempty(onset)
%     vowel_ampl = nanmean(rmsdata(onset:end));
% else
%     vowel_ampl = 0;
% end

if currAmp <= params.max_ampl && currAmp >= params.min_ampl
    success = 1;
else
    success = 0;
end

if ~bPtb
    h_ampl = draw_amplFB(h_fig,currAmp,params);
else
    h_ampl = [];
    draw_amplFB_ptb(h_fig,currAmp,params);
end
% %plot feedback
% figure(h_fig)
% if vowel_ampl <= params.max_ampl && vowel_ampl >= params.min_ampl
%     h_ampl(1) = rectangle('Position',[.45,.15,.0001,.0001],'Curvature',[1,1],'Facecolor', 'g');
%     success = 1;
% elseif vowel_ampl > params.max_ampl
%     h_ampl(1) = rectangle('Position',params.circ_pos,'Curvature',[1,1],'Facecolor', 'r');
%     h_ampl(2) = text(params.circ_pos(1)+0.05,params.circ_pos(2)-0.05,{'Speak more quietly'}, 'Color', 'r', 'FontSize', 50,'HorizontalAlignment','Center');
%     success = 0;
% elseif vowel_ampl < params.min_ampl
%     h_ampl(1) = rectangle('Position',params.circ_pos,'Curvature',[1,1],'Facecolor', 'c');
%     h_ampl(2) = text(params.circ_pos(1)+0.05,params.circ_pos(2)-0.05,{'Speak louder'}, 'Color', 'c', 'FontSize', 50,'HorizontalAlignment','Center');
%     success = 0;
% end
