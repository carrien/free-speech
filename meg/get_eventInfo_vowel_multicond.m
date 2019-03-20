function [eventInfo] = get_eventInfo_vowel(dataPath,cond,othercond)
%GET_EVENTINFO_VOWEL  Get event info for trials by vowel identity.
%   GET_EVENTINFO_VOWEL(DATAPATH,CONDITION) uses trial information from
%   expt.mat to construct eventInfo grouped by vowel identity. COND
%   determines which events will be tracked and can be 'speak', 'listen',
%   or 'both'.
%   Because expt.mat does not exclude bad trials, they are included here
%   and must be removed downstream, e.g. after matching the event info to
%   Brainstorm events imported in the database.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(cond), cond = 'both'; end

load(fullfile(dataPath,'expt.mat'));

fullfile(dataPath,othercond,'dataVals.mat')

if exist(fullfile(dataPath,'dataVals.mat'))
    load(fullfile(dataPath,'dataVals.mat'));
    exclude = [dataVals.bExcl];
    excludeindices = find(exclude==1);
    tokens = [dataVals.token];
    excludetrials = tokens(excludeindices);
end

eventInfo = struct([]);
if strcmpi(othercond,'English')
conds = {'EnglishSpeak','EnglishListen'};
else
    conds = {'FrenchSpeak','FrenchListen'};
end

for c=1:length(conds)
    thiscond = conds{c};
    if any(strcmp(cond,{thiscond,'both'})) % if condition matches this cond (or is 'both')
        len = length(eventInfo);
        for v=1:length(expt.vowels)
            thisvowel = expt.vowels{v};
            eventInfo(v+len).name = sprintf('%s_%s',thiscond,thisvowel);
            eventInfo(v+len).color = rand(1,3);
            thisvowelinds = expt.inds.vowels.(thisvowel);
            if exist('excludetrials','var')
                trials2rm = intersect(thisvowelinds,excludetrials);
                    if ~isempty(trials2rm)
                        [inds2rm] = ismember(thisvowelinds,trials2rm);
                        thisvowelinds(inds2rm) = [];
                        % TO DO: WHERE INDS ARE EQ TO TRIALS2RM
                    end
            end
            eventInfo(v+len).trialinds = thisvowelinds;
        end
    end
end

