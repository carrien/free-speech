function [expt] = randomize_stimuli(expt, nTrialsPerPert, nTrialsPerNonpert, nBaseline, nWashout)
% Pseudorandomize words and conditions for experiments.
%
% Input arguments:
%   EXPT. The expt file is assumed to have the following fields:
%       expt.nblocks, the number of blocks.
%       expt.ntrials_per_block, the number of trials in each block.
%       expt.words, a cell array of the words in the experiment
%       expt.conds, a cell array of the names of each condition
%   NTRIALSPERPERT. In each block, the number of trials that each unique
%       word-condition pair should be, for perturbation conditions. For
%       example, if you have 3 words and 2 perturbation conditions, the
%       number of trials PER BLOCK that are "word1 with perturbation cond2"
%   NTRIALSPERNONPERT. In each block, the number of trials that should be
%       used for each word-condition pair, for non-perturbation conditions.
%       For example, if you have three words (and you necessarily only have
%       one non-perturbation condition), the number of trials PER BLOCK
%       that should be "word1 with no perturbation". 
%   NBASELINE. Optional. (Default = 0). If there are trials at the
%       BEGINNING of the experiment where every trial should be the noPert
%       condition (or specifically, the first indexed condition in expt.conds),
%       specify that number of trials here. If this isn't a multiple of
%       expt.ntrials_per_block, you may have an uneven # of pert trials.
%   NWASHOUT. Optional. (Default = 0). If there are trials at the END of
%       the experiment where every trial should be the noPert condition 
%       (or specifically, the first indexed condition in expt.conds),
%       specify that number of trials here. If this isn't a multiple of
%       expt.ntrials_per_block, you may have an uneven # of pert trials.
%
% CWN v1 2021-01


%% Requirements for this pseudorandomization procedure:

%{
1. Within a block, each word in expt.words appears the same number of times.
2. Each word is assigned to perturbation ("pert") conditions the same number
    of times. So if there are 3 words and 2 pert conditions and
    nTrialsPerPert = 1, there will be 6 pert trials (3 * 2 * 1).
3. Each word is assigned to the non-pert conditions the same number of
    times. So if there are 3 words and nTrialsPerNonpert = 4, there will be
    12 non-pert trials (3 * 1 * 4). It is assumed that there is only 1
    non-pert condition.
4. No pert trial immediately follows any other pert trial, even across
    block boundaries.
5. nBaseline and nWashout can override a trial's condition (but not word)
    and set the value to the non-pert condition.

NOTE: Because of #4, this function won't work if you have more pert trials
    than nonpert trials.
%}
%% The following method was used for each block.
%{
First, each type of trial gets a number 0-8, where `mod(#, 3) + 1` is the
condition index (see expt.conds), and `floor(#/3) + 1` is the word index.
Save these values in ordered vectors called pertTrials_ordered and
nonpertTrials_ordered. For each block, randomize the order of these values
within two vectors, pertTrials and nonpertTrials.

Then, pair each perturbation trial type with a non-perturbation trial type.
These trials will appear sequentially. Pairing this way ensures there can
never be sequential perturbation trials.

Then, in short, randomly arrange the paired pert-nonpert trials alongside
the remaining nonpert trials.

Lastly, override condition values if nBaseline or nWashout are in use.
%}


%% Sample input
%{
With the following setup:
   expt.words = {'head' 'bed' 'dead'}, such that length = 3
   expt.conds = {'noPert' 'shiftIH' 'shiftAE'}, such that length = 3
   expt.ntrials_per_block = 18
   INPUT ARGUMENT: nTrialsPerPert = 1
   INPUT ARGUMENT: nTrialsPerNonpert = 4

Then within each block, you would get:
  12 noPert trials (4 trials for each word)
  3 shiftIH trials (1 trial for each word)
  3 shiftAE trials (1 trial for each word)

  And:
      pertTrials_ordered = [1 2 4 5 7 8];
      nonpertTrials_ordered = [0 0 0 0 3 3 3 3 6 6 6 6];
%}
%% Setup
% confirm input parameters are possible with expt configuration
if expt.ntrials_per_block ~= (nTrialsPerNonpert*length(expt.words)) + ...
        (nTrialsPerPert * (length(expt.words) * (length(expt.conds)-1)))
    error(['The math doesn''t check out. Make sure you''ve accurately set ' ...
        'each of the parameters for this function. See header or sample ' ...
        'input listed above for help.']);
end

if nargin < 4 || isempty(nBaseline)
    nBaseline = 0;
end
if nargin < 5 || isempty(nWashout)
    nWashout = 0;
end


rng('shuffle');
listWordCond = [];


%% build pertTrials_ordered and nonpertTrials_ordered
numWordsConds = length(expt.words) * length(expt.conds);
pertTrials_ordered = [];
nonpertTrials_ordered = [];
for i = 0:1:(numWordsConds-1)
    if mod(i, length(expt.conds))
        pertTrials_ordered = [pertTrials_ordered i*ones(1, nTrialsPerPert)];
    else
        nonpertTrials_ordered = [nonpertTrials_ordered i*ones(1, nTrialsPerNonpert)];
    end
end

if length(pertTrials_ordered) > length(nonpertTrials_ordered)
    error('There cannot be more pert trials than nonpert trials. (Otherwise adjacency rules are broken.)');
end

%% Loop for each block
for iblock = 1:expt.nblocks
    pertTrials = pertTrials_ordered;
    nonpertTrials = nonpertTrials_ordered;
    
    pertTrials = pertTrials(randperm(length(pertTrials_ordered)));
    nonpertTrials = nonpertTrials(randperm(length(nonpertTrials_ordered)));
    
    % pair a pert trial with a nonpert trial. hold remaining nonpert trials
    pertPair = [pertTrials; nonpertTrials(1:length(pertTrials))];
    nonpertLeftover = nonpertTrials(length(pertTrials)+1:expt.ntrials_per_block - length(pertTrials));
    
    % randomly-ordered vector of 0's for pertPair and 1's for nonpertLeftover
    ix = [zeros(1, size(pertPair,2)), ones(1, length(nonpertLeftover))];
    ix = ix(randperm(length(ix)));
    
    pertIx = 1;
    nonpertIx = 1;
    % match up pert-nonpert pairs with remaining nonpert trials
    for i = 1:length(ix)
        if ix(i)
            listWordCond = [listWordCond nonpertLeftover(nonpertIx)];
            nonpertIx = nonpertIx + 1;
        else
            listWordCond = [listWordCond pertPair(1, pertIx) pertPair(2, pertIx)]; %#ok<*AGROW>
            pertIx = pertIx + 1;
        end
    end
    
end

%% Put it back into expt format
expt.allWords = floor(listWordCond/length(expt.conds)) + 1;
expt.listWords = expt.words(expt.allWords);
expt.allConds = mod(listWordCond, length(expt.conds)) + 1;

% set baseline and washout trials to the noPert condition
if nBaseline > 0 
    expt.allConds(1:nBaseline) = 1;
end
if nWashout > 0
    expt.allConds(end-nWashout+1:end) = 1;
end

expt.listConds = expt.conds(expt.allConds);


end