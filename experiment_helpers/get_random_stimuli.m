function [expt] = get_random_stimuli(expt, nTrialsPerPert, nTrialsPerNonpert, nBaselineTrials)
% Pseudorandomize words and conditions for experiments.
%{
The following restrictions were used for pseudorandomization:

1. Each 18-trial block contains 6 instances of each of the three words.
2. Each block has 3 trials that are accelerated and 3 trials that are
    decelerated. Each word gets 1 accel and 1 decel. So, each block has 12
    unperturbed trials (conds = 'noShift') and 6 perturbed trials.
3. Rule #2 does not apply for the first block, which is a baseline. In the
    baseline block, all trials are unperturbed.
4. No perturbed trial (either accel or decel) immediately follows any
    other perturbed trial, even across block boundaries.

This pseudorandom was completed using the following method for each block.
First, each type of trial gets a number 0-8, where `mod(#, 3) + 1` is the
condition index (see expt.conds), and `floor(#/3) + 1` is the word index.
Randomize the order of these values within two vectors, pertTrials and nonpertTrials.

Then, pair each perturbation trial type with a non-perturbation trial type.
These trials will appear sequentially. Pairing this way ensures there can
never be sequential perturbation trials.

Lastly, in short, randomly arrange the paired pert-nonpert trials alongside
the remaining nonpert trials.
%}
% CWN v1 2021-01

% TODO fix header information
% TODO add more comments.
% ASSUMES:
    %expt.nblocks
    %expt.words
    %expt.conds
    %expt.ntrials_per_block
    

% Need: number of words                       length(expt.words)
% Number of pert conditions                   expt.conds -1
% Number of trials in each pert condition     nTrialsPerPert
% Number of non-pert trials                   nTrialsPerNonpert

if nargin < 4 || isempty(nBaselineTrials)
    nBaselineTrials = 0;
end


rng('shuffle');
listWordCond = [];

%build pertTrials and nonpertTrials
numWordsConds = length(expt.words) * length(expt.conds);
pertTrials_ordered = [];
nonpertTrials_ordered = [];
for i = 0:1:(numWordsConds-1)
    if mod(i, length(expt.words))
        pertTrials_ordered = [pertTrials_ordered i*ones(1, nTrialsPerPert)];
    else
        nonpertTrials_ordered = [nonpertTrials_ordered i*ones(1, nTrialsPerNonpert)];
    end
end

% As an example, with the following setup:
%    ntrials_per_block = 18
%    nTrialsPerPert = 1
%    nTrialsPerNonpert = 4
%    expt.words = {'head' 'bed' 'dead'}, such that length = 3
%    expt.conds = {'noPert' 'accel' 'decel'}, such that length = 3
%
% Then the following would be true
%    pertTrials = [1 2 4 5 7 8];
%    nonpertTrials = [0 0 0 0 3 3 3 3 6 6 6 6];


for iblock = 1:expt.nblocks
    pertTrials = pertTrials_ordered;
    nonpertTrials = nonpertTrials_ordered;
    
    pertTrials = pertTrials(randperm(length(pertTrials_ordered)));
    nonpertTrials = nonpertTrials(randperm(length(nonpertTrials_ordered)));
    
    pertPair = [pertTrials; nonpertTrials(1:length(pertTrials))];
    nonpertLeftover = nonpertTrials(length(pertTrials)+1:expt.ntrials_per_block - length(pertTrials));
    
    % randomly-ordered vector of 0's for pertPair and 1's for nonpertLeftover
    ix = [zeros(1, length(pertPair)), ones(1, length(nonpertLeftover))];
    ix = ix(randperm(length(ix)));
    
    pertIx = 1;
    nonpertIx = 1;
    for i = 1:length(ix)
        if ix(i)
            listWordCond = [listWordCond pertPair(1, pertIx) pertPair(2, pertIx)]; %#ok<*AGROW>
            pertIx = pertIx + 1;
        else
            listWordCond = [listWordCond nonpertLeftover(nonpertIx)];
            nonpertIx = nonpertIx + 1;
        end
    end
    
end


expt.allWords = mod(listWordCond, length(expt.words)) + 1;
expt.listWords = expt.words(expt.allWords);

expt.allConds = floor(listWordCond/length(expt.words)) + 1;
for i = 1:nBaselineTrials
    expt.allConds(i) = 1;
end
expt.listConds = expt.conds(expt.allConds);


end