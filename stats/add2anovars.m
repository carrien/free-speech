function [obs,group] = add2anovars(obs,new_obs,group,varargin)
%ADD2ANOVARS  Add observed data and appropriate ANOVA grouping variables.
%   ADD2ANOVARS(OBS,GROUP,NEW_OBS,VARARGIN) takes a vector of observed data
%   OBS and adds the new observed data in NEW_OBS. Each cell in the array
%   of anova grouping variables GROUP is extended by a vector the same
%   length as NEW_OBS containing copies of a single integer stored in
%   VARARGIN. VARARGIN should be the same length as GROUP.
%
% Example:
%
% obs = []; group = [];
% for s = 1:length(subj)
%     sid = subj{s};
%     for c = 1:length(conds)
%         cnd = conds{c};
%         for v = 1:length(vowels)
%             vow = vowels{v};
%
%             newdata = data(sid).(cnd).(vow);
%             [obs,group] = add2anovars(obs,newdata,group,s,c,v);
%
%         end
%     end
% end

if isempty(group)
    group = cell(1,length(varargin));
end

% add to vector of observed data
obs = [obs; new_obs];

% add categorical data to each grouping variable
nObs = length(new_obs);
for v = 1:length(varargin)
    thisgroup = varargin{v};
    if isnumeric(thisgroup)
        if length(thisgroup)==1                   % if a number
            group{v} = [group{v}; thisgroup*ones(nObs,1)];
        elseif iscolumn(thisgroup) && length(thisgroup)==nObs
            group{v} = [group{v}; thisgroup];            
        elseif isrow(thisgroup) && length(thisgroup)==nObs
            group{v} = [group{v}; thisgroup'];            
        else
            error('Length of grouping variable is %d. Grouping variable must either be a single element or have the same number of elements as the data to be added (length:).',length(thisgroup),nObs);
        end
    elseif ischar
        error('String format not yet supported for grouping variables.')
    elseif iscell
        error('Cell format not yet supported for grouping variables.')
    end
end
