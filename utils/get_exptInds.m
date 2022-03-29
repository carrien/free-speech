function [inds] = get_exptInds(expt,elements)
%GET_EXPTINDS  Calculate indices of trial types for an expt object.
%   GET_EXPTINDS(EXPT,ELEMENTS)

allElements = cell(1,length(elements));
goodIxs = [];

% remove elements without both expt.element and expt.allElements
for ie = 1:length(elements)
    allElements{ie} = sprintf('all%s%s',upper(elements{ie}(1)),elements{ie}(2:end));
    if isfield(expt, elements{ie}) && isfield(expt, allElements{ie}) && ...
            ~isempty(expt.(elements{ie})) && ~isempty(expt.(allElements{ie}))
        goodIxs = [goodIxs ie]; %#ok<AGROW> 
    end
end

elements = elements(goodIxs);
allElements = cell(1, length(elements));

for ie=1:length(elements)
    allElements{ie} = sprintf('all%s%s',upper(elements{ie}(1)),elements{ie}(2:end));
    for ia=1:length(expt.(elements{ie}))
        inds.(elements{ie}).(expt.(elements{ie}){ia}) = find(expt.(allElements{ie}) == ia);
    end
end
