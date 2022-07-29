function [expt] = randomize_stimuli(expt, nTrialsPerPert, nTrialsPerNonpert, nBaseline, nWashout, bAlternatePnp)
% Pseudorandomize words and conditions for experiments. Specifically meant for experiments that have more than one
% perturbation AND more than one word. For experiments where you are only randomizing one of the variables, see
% randomize_wordOrder. 
%
% Input arguments:
%   EXPT. The expt file is assumed to have the following fields:
%       - expt.nblocks, the number of blocks, including any baseline and washout blocks
%       - expt.ntrials_per_block, the number of trials in each block.
%       - expt.words, a cell array of the words in the experiment
%       - expt.conds, a cell array of the names of each condition. 
%       ***** The no perturbation condition must be the first member of this cell array, e.g. {'noPert' 'accel' 'decel'}
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
%   bAlternatePnp       Default = 1 (to assume the original behavior of this script). binary "alternate perturbed and
%                       non-perturbed"
%                       This is a binary flag to indicate if you are doing an experiment where no perturbed trial can be next
%                       to another perturbed trial (bAlternatePnp = 1) or if you are doing an experiment where you just don't
%                       want two of the same word OR same perturbation to be next to each other (bAlternatePnp = 0). 
% 
%                       E.g. with bAlternatePnp = 0, a sequence of sigh/accel side/decel would be acceptable. 
%                       With bAlternatePnp = 1, the sequence would have to be (e.g.) sigh/accel side/noPert side/decel
% 
%                       Note that with bAlternatePnp = 1, you may still have two of the same word together or two of the same
%                       cond together (specifically two non perturbed trials together). With bAlternatePnp = 0, no adjacent
%                       trials will share either characteristic. 
% 
%                       Note also that you can actually use this function with bAlternatePnp set to 0 even if you don't have 
%                       any nonpert trials. A potential use case is a compensation experiment with many different 
%                       perturbations where there is no concern about learning as long as the same kinds of trials don't 
%                       occur together. In this case, set nTrialsPerNonpert to the same as nTrialsPerPert. The algorithm 
%                       treats everything equally other than the weighting (repetitions per condition). 
% 
% 
%
% CWN v1 2021-01
% RPK added bAlternatePnp flag 2022-07-28


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
4. If bAlternatePnp == 1, no pert trial immediately follows any other pert trial, even across
    block boundaries. If bAlternatePnp == 0, adjacent trials cannot share word or perturbation, 
    but perturbed trials can be next to each other. 
5. nBaseline and nWashout will override a trial's condition (but not word)
    and set the value to the non-pert condition.

NOTE: Because of #4, this function won't work if you have more pert trials
    than nonpert trials and have bAlternatePnp set to 1. 
%}
%% The following method was used for each block: 
%{
bAlternatePnp = 1
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

============================================================================
bAlternatePnp = 0
First, I did a more complicated way of getting the same result as above. Every unique type of trial gets a single number. It
is then put into a table where row = word index and column = condition index. 

A table of weights is then drawn up, which is essentially the number of repetitions that particular word/cond combination has
in a block. 

There is a random weighted draw based on the unique identifiers and the repetitions remaining for that unique identifier.
After a trial type is selected, the weight table is decremented for that trial type. Furthermore, the weights for any trial
type that shares the same word (row) or the same condition (column) is set to 0 so it will not be picked in the next trial's
random selection. 

Sometimes the random walk type weighted selection will not pick an optimal order of trials and so near the end of the block
may have painted itself into a corner and has nothing left to draw from that satisfies adjacency conditions. If that is the
case, the process will start over for the block. 

I have not put in any smart mathematical ways of avoiding rep/cond/word combos that are literally impossible, but there is a 
guard against infinite loops where it will only attempt to order a block ntrials_per_block * 1000 times. (In testing with a 
few different parameters in the reasonable block size range, I don't tend to surpass 10 attempts or 50 at the higher end, so 
anything beyond 1000*ntrials_per_block is likely to be very difficult/mathematically impossible)

If you do surpass the maximum number of attempts, the block will get put into the experiment-wide vector of unique trial
types. It will have zeros instead of actual numbers in the trials that could not be solved. (Future option is to check if
there was a previous block that DID work and use that if so, but as mentioned, surpassing 1000*ntrials attempts is not a
great sign so there might not be any successful ones at all)

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
if nargin < 6 || isempty(bAlternatePnp)
    bAlternatePnp = 1; 
end


rng('shuffle');
listWordCond = [];

%% Loop for each block

%% Alternating perturbed and not perturbed trials (specifically, you can't have perturbed trials together)
if bAlternatePnp

    % build pertTrials_ordered and nonpertTrials_ordered
    numWordsConds = length(expt.words) * length(expt.conds);
    pertTrials_ordered = [];
    nonpertTrials_ordered = [];
    for t = 0:1:(numWordsConds-1)
        if mod(t, length(expt.conds))
            pertTrials_ordered = [pertTrials_ordered t*ones(1, nTrialsPerPert)];
        else
            nonpertTrials_ordered = [nonpertTrials_ordered t*ones(1, nTrialsPerNonpert)];
        end
    end

%     if length(pertTrials_ordered) > length(nonpertTrials_ordered)
%         error('There cannot be more pert trials than nonpert trials. (Otherwise adjacency rules are broken.)');
%     end
%     
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

        condIx = 1;
        nonpertIx = 1;
        % match up pert-nonpert pairs with remaining nonpert trials
        for t = 1:length(ix)
            if ix(t)
                listWordCond = [listWordCond nonpertLeftover(nonpertIx)];
                nonpertIx = nonpertIx + 1;
            else
                listWordCond = [listWordCond pertPair(1, condIx) pertPair(2, condIx)]; %#ok<*AGROW>
                condIx = condIx + 1;
            end
        end

    end

    % Put into expt
    expt.allWords = floor(listWordCond/length(expt.conds)) + 1;
    expt.listWords = expt.words(expt.allWords);
    expt.allConds = mod(listWordCond, length(expt.conds)) + 1;

%% Not alternating perturbed and unperturbed; no word/pert adjacency
else

    % Generate unique word/perturbation combination information 
    nWords = length(expt.words); 
%     nPerts = length(expt.conds)-1;  
    nConds = length(expt.conds); 
%     allWordsInBlock = []; 
    uniqueWordsInBlock = []; 
    % Loop through each word. This builds vectors like this: (nTrialsPerPert = 2, nTrialsPerNonpert = 2)
    % word:     1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2
    % cond:     2 3 4 2 3 4 1 1 2 3 4 2 3 4 1 1
    % Actually the thing that I ended up needing is 
    % uniquewords:      1 1 1 1 1 1 1 1 1 1
    % uniqueconds:      2 3 4 5 1 2 3 4 5 1             
    % Where any of the unique word/cond combos may be repeated in the actual block, but they are just repetitions (not
    % unique and thus do not get a unique number identifier) (though I guess that is a way to do this as well, where instead
    % of weighting I just had more entries in the draw table? Not as easy to eliminate one column/one row then though) 
    for w = 1:nWords
        % Build the list of instances that will occur in each block
%         newWordNums = repmat(w, 1, nTrialsPerPert*nPerts + nTrialsPerNonpert);      % Make a vector of the instances of perturbed word + instances of unperturbed word
%         allWordsInBlock = [allWordsInBlock newWordNums];                      % Chain that to the whole block 
        uniqueWordConds = repmat(w, 1, nConds);                                 % I don't think I actually use this
        uniqueWordsInBlock = [uniqueWordsInBlock uniqueWordConds]; 
    end
    
    % Do a similar thing for the perturbation conditions that will occur in each block
%     newCondNums = [repmat(2:nConds, 1, nTrialsPerPert) ones(1, nTrialsPerNonpert)];   % Note that nPerts is PERTURBED (length(expt.conds)-1) so you need length(expt.conds)
%     allCondsInBlock = repmat(newCondNums, 1, nWords);                            % Repmat this for each word. Apparently this is not useful ... 
    uniqueCondsInBlock = [repmat([2:nConds 1], 1, nWords)];                      % this has a single entry for each unique word/cond combo 
                                                                                 % (allCondsInBlock has repeats for any condition that has more than one rep)
    
    % Make a vector that has a single number assigned to each unique word/pert combination
    allWordConds = 1:(nWords*nConds); 
    
    % Now make a table where one row = one word and one column = one condition
    wordCondTable = zeros(nWords, nConds);     
    for a = 1:length(allWordConds)
       allWordCond = allWordConds(a); 
       
       % Get the position to put the unique identifier number in in the table. 
        % Row: word 
        % Column: pert
       whatRow = uniqueWordsInBlock(allWordCond); 
       whatColumn = uniqueCondsInBlock(allWordCond); 
       
       % Set that position in the table
       wordCondTable(whatRow, whatColumn) = allWordCond;    
    end
    
    % Now make the weights (i.e., the repetitions that each word/cond combo has)
    wordCondReps = zeros(nWords, nConds); 
    wordCondReps(:, 1) = nTrialsPerNonpert;                                  % The first column is the non-pert condition
    wordCondReps(:, 2:end) = nTrialsPerPert;                                 % All other cells are the number of perturbed trials
    preserveWordCondReps = wordCondReps; 
    
    % The actual randomization procedure    
    % Your possible options (this never changes)
    drawFrom = reshape(wordCondTable, 1, []); 
    experimentWordConds = []; 
    for b = 1:expt.nblocks        
        % Set the weights for each option to the original repetition state 
        wordCondReps = preserveWordCondReps;                                                  % Reset to original repetitions for each block 
        weights = reshape(wordCondReps, 1, []);                                          % Flatten for not having to sum everything
        drawWeights = weights/sum(weights);
        
        % Start counters
        t = 1; % trial counter
        attempts = 1; % To count the number of attempts in case you run into a problem (no infinite loops)
        maxAttempts = expt.ntrials_per_block*1000; 
        
        % Initialize the vector for the block
        blockWordConds = zeros(1, expt.ntrials_per_block); 
        while t <= expt.ntrials_per_block
            % Get a word/cond combo from your list of possible wordconds 
            try
                trialWC = randsample(length(drawFrom), 1, true, drawWeights);                 
                % Provision for not having adjacent trials across block boundaries either 
                if b > 1 && t == 1
                    [wordIx, condIx] = find(wordCondTable == drawFrom(trialWC)); 
                    matchedWC = [wordCondTable(wordIx,:) wordCondTable(:,condIx)']; 
                    
                    while any(matchedWC == drawFrom(trialWC))
                        trialWC = randsample(length(drawFrom), 1, true, drawWeights); 
                    end
                end
            catch
                % Catch statement is because sometimes you will hit a bad sequence and you won't have any good options left
                % Reset trial counter, 
                t = 1; 
                blockWordConds = zeros(1,expt.ntrials_per_block);                               % Empty out the block vector, 
                
                % Reset the weights, 
                wordCondReps = preserveWordCondReps;                                                  % Reset to original repetitions for each block 
                weights = reshape(wordCondReps, 1, []);                                          % Flatten for not having to sum everything
                drawWeights = weights/sum(weights);        
                
                % Escape hatch for infinite loops                
                if attempts > maxAttempts
                    warning('I''ve tried block %d too many times. I''m going to use the last attempted order but you might have an incomplete block.\n', b) % ***** TODO MAKE THIS BETTER 
                    experimentWordConds = [experimentWordConds blockWordConds]; 
                    break; % Don't try this block anymore
                end
                attempts = attempts+1; % 
                continue; % Try this block one more time 
            end
            
            % Set the trial's unique identifier
            blockWordConds(t) = drawFrom(trialWC); 
            
            % Find the word and column that you won't be able to use next time
            [wordIx, condIx] = find(wordCondTable == blockWordConds(t)); 

            % Decrement the weights 
            wordCondReps(wordIx, condIx) = wordCondReps(wordIx, condIx) - 1; 
            
            % Make the new drawweight vector. This is the updated wordCondReps, with everything that is in the same word or pert column
            % set to 0 
            drawWeightTable = wordCondReps; 
            drawWeightTable(wordIx, :) = 0; % Change the same word/pert condition ones to 0 
            drawWeightTable(:, condIx) = 0; 
            drawWeights = reshape(drawWeightTable, 1, []); 
            drawWeights = drawWeights/sum(drawWeights); 

            % Increment trial
            t = t+1; 
        end
        
        % When you have a good block, add it to the experiment list 
        experimentWordConds = [experimentWordConds blockWordConds]; 
%         fprintf('Block %d: %d attempts\n', b, attempts); 
    end
    
    % Translate unique word/conds back into the words and the conds 
    allWords = uniqueWordsInBlock(experimentWordConds); 
    allConds = uniqueCondsInBlock(experimentWordConds); 
    
    % Put into expt
    expt.allWords = allWords; 
    expt.listWords = expt.words(allWords); 
    expt.allConds = allConds; 
    expt.listConds = expt.conds(allConds);   
    
end



%% set baseline and washout trials to the noPert condition
if nBaseline > 0 
    expt.allConds(1:nBaseline) = 1;
    if mod(nBaseline, expt.ntrials_per_block)
        warning('The requested number of baseline trials does not form complete blocks. You may have unequal numbers of perturbed words.')
    end
end
if nWashout > 0
    expt.allConds(end-nWashout+1:end) = 1;
    if mod(nWashout, expt.ntrials_per_block)
        warning('The requested number of washout trials does not form complete blocks. You may have unequal numbers of perturbed words.')
    end
end

expt.listConds = expt.conds(expt.allConds);


end % EOF