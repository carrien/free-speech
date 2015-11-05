% CLEAREXCEPT   Clear variable workspace (except for KEEPER).
% e.g. keeper = vartokeep; clearexcept;

w = who;
for i=1:length(w)
    if ~strcmp(w{i},keeper) && ~strcmp(w{i},'keeper') && ~strcmp(w{i},'i') && ~strcmp(w{i},'w')
        clear(w{i})
    end
end
clear i
clear w
clear keeper