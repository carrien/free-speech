function [inds] = get_exptInds(expt,elements)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%indall = {'conds', 'words', 'vowels'};
%indlist = {'allConds', 'allWords', 'allVowels'};
allElements = cell(1,length(elements));
for ie=1:length(elements)
    allElements{ie} = sprintf('all%s%s',upper(elements{ie}(1)),elements{ie}(2:end));
    for ia=1:length(expt.(elements{ie}))
        inds.(elements{ie}).(expt.(elements{ie}){ia}) = find(expt.(allElements{ie}) == ia);
    end
end
