function [eventInfo] = get_eventInfo_vowel(dataPath,cond)
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

eventInfo = struct([]);
conds = {'speak','listen'};
for c=1:length(conds)
    thiscond = conds{c};
    if any(strcmp(cond,{thiscond,'both'})) % if condition matches this cond (or is 'both')
        len = length(eventInfo);
        for v=1:length(expt.vowels)
            thisvowel = expt.vowels{v};
            eventInfo(v+len).name = sprintf('%s_%s',thiscond,thisvowel);
            eventInfo(v+len).color = rand(1,3);
            eventInfo(v+len).trialinds = expt.inds.vowels.(thisvowel);
        end
    end
end
