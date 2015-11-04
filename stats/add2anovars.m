function [obs,group] = add2anovars(obs,new_obs,group,varargin)
%ADD2ANOVARS  Add observed data and appropriate ANOVA grouping variables.
%   ADD2ANOVARS(OBS,GROUP,NEW_OBS,VARARGIN) takes a vector of observed data
%   OBS and adds the new observed data in NEW_OBS. Each cell in the array
%   of anova grouping variables GROUP is extended by a vector the same
%   length as NEW_OBS containing copies of a single integer stored in
%   VARARGIN. VARARGIN should be the same length as GROUP.

if isempty(group)
    group = cell(1,length(varargin));
end

% add to vector of observed data
obs = [obs; new_obs];

% add categorical data to each grouping variable
for v = 1:length(varargin)
    group{v} = [group{v}; varargin{v}*ones(length(new_obs),1)];
end

