function allWords = randomize_wordOrder(nWords, nBlocks)
% Given a certain number of words and certain number of blocks,
% returns a random ordering of word indeces to fill those blocks.
%
% Operates with the following restrictions:
%   1. Each block is nWords trials long
%   2. Each block has 1 instance of each word. (More specifically, each
%           block has 1 instance of each number).
%   3. Adjacent blocks do not have matching edges. That is, if one block
%   has the word order [1 2 3], the next block will not begin with [3].
%   
% Due to the above rules, no word/number will ever appear on two trials in a row.
%
% The output of this function is made to be directly plugged into expt.allWords.
% 
% Input args: 
% 
%   1   nWords                  Number of unique words 
% 
%   2   nBlocks                 Total number of blocks that you want. One
%                               block has each unique word once. 
%
% 2021 Lana Hantzsch init
% 2021-09 Chris Naber documentation and generalization
% 2022-03 Chris Naber generalize via changing input arguments

rng('shuffle');

for bIx = 1:nBlocks
    block = randperm(nWords);
    
    % keep using randperm until you get a permutation where there's no
    % matching edge with the previous block.
    while bIx~=1 && allWords((bIx-1)*nWords) == block(1)
        block = randperm(nWords);
    end
    
    % add "good" block of trials to allWords
    allWords((bIx*nWords)-(nWords-1) : (bIx*nWords)) = block;
end


end % EOF