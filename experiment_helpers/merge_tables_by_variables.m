function [mergedTable] = merge_tables_by_variables(refTab, secondTab, VariablesCell, mergeVarCell, suffix)

% oldVar = refTab.(mergeVar);
% newVar = zeros(size(oldVar));

mergedTable = refTab;

for nv = 1:length(mergeVarCell)
    newVar = mergeVarCell{nv};
    newVarN = [newVar suffix];
    if iscell(refTab.(newVar))
        mergedTable.(newVarN) = cell(size(refTab,1),1);
    elseif isnumeric(refTab.(newVar))
        mergedTable.(newVarN) = zeros(size(refTab,1),1);
    end
end

for r = 1:size(refTab,1)
    minitab = secondTab;
    for v = 1:length(VariablesCell)
        thisvar = VariablesCell{v};
        compvar = refTab.(thisvar)(r);
        if strcmpi(class(compvar),'cell')
            minitab = minitab(strcmpi(minitab.(thisvar),compvar),:);
        elseif strcmpi(class(compvar),'double')
            minitab = minitab(minitab.(thisvar) == compvar,:);
        end
    end
    
    if ~isempty(minitab)
        for nv = 1:length(mergeVarCell)
            newVar = mergeVarCell{nv};
            newVarN = [newVar suffix];
            if size(minitab,1)>1
                error('Duplicate rows?')
            else
                mergedTable.(newVarN)(r) = minitab.(newVar)(1);
            end
        end
    end
end
