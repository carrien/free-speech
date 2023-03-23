function [savefile] = gen_fmtMatrix_modelExpt(dataPath,dataValsStr,bSaveCheck)
% This is a template function which must be modified to work. Comments
%   with "ACTION NEEDED" tell you how to make it work.
%
% This function takes your dataVals file and makes a fmtMatrix file, which
%   is used for plotting. You choose how to group trials together; most
%   often trials are grouped by condition, or word, or condition and word.
%
% INPUT ARGUMENTS
%   dataPath:   The filepath which contains expt.mat and dataVals.mat
%   dataValsStr:   The exact name of the file which contains the dataVals
%       variable. By default it's 'dataVals.mat'
%   bSaveCheck:   A binary 1/0 for if the system should ask before
%   overwriting an existing file. 


if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end

load(fullfile(dataPath,'expt.mat'),'expt');

% ACTION NEEDED - UPDATE VALUES
% This function assumes that your experiment varies by "condition" (such as
%   shiftUp, noShift) and by "word" (such as bed, head).
%
% Look in expt.conds and set the below variables based on the baseline vs
%   experimental condition names.
conds = {'shiftUp','shiftDown'}; 
basecond = 'noShift';
words = expt.words;

colors.shiftUp = [.2 .6 .8];    % blue
colors.shiftDown = [.8 0 0];    % red
colors.noShift = [.5 .5 .5];    % grey

% ACTION NEEDED - MAKE A CHOICE
% Decide how to group your data. Comment out or delete the other option.
%
% With option A, fmtMatrix will compare across conditions, but will
%   collapse all words together. For example, all instances of "bed" and
%   "head" under the noShift condition will be grouped as "noShift".
%
% With option B, fmtMatrix will compare across conditions and word and will
%   keep them distict. For example, "bed + noShift" and "head + noShift"
%   will be distict groups. 
%
%   HOW TO DECIDE? 
% Option A is a GOOD idea if your "words" are 
%   sustained vowels, or if your perturbation is applied mid-utterance, and
%   so you're going to ignore the first ~100ms of the vowel anyway.
% Option B is a GOOD idea if your words have different onsets like "bed"
%   and "ted", since coarticulatory effects impact the formants at vowel
%   onset. (Assuming you care about the formants at vowel onset.)

%% OPTION A - separate only by condition
for c=1:length(conds)
    cond = conds{c};
    indShift(c).name = cond;
    indShift(c).inds = expt.inds.conds.(cond);
    indShift(c).shiftind = c;
    indShift(c).linecolor = colors.(cond);
    
    indBase(c).name = basecond;
    indBase(c).inds = expt.inds.conds.(basecond);
    indBase(c).linecolor = colors.(basecond);
end

%% OPTION B - separate by condition and word
% for c=1:length(conds)
%     cond = conds{c};
%     for w=1:length(words)
%         word = words{w};
%         shiftnum = (c-1)*nwords + w;
%         
%         indShift(shiftnum).name = sprintf('%s%s',cond,word);
%         indShift(shiftnum).inds = intersect(expt.inds.conds.(cond),expt.inds.words.(word));
%         indShift(shiftnum).shiftind = c;
%         indShift(shiftnum).linecolor = colors.(cond);
%         
%         indBase(shiftnum).name = sprintf('%s%s',basecond,word);
%         indBase(shiftnum).inds = intersect(expt.inds.conds.(basecond),expt.inds.words.(word));
%         indBase(shiftnum).linecolor = colors.(basecond);
%     end
% end



savefile = gen_fmtMatrixByCond(dataPath,indBase,indShift,dataValsStr,1,1,bSaveCheck);
