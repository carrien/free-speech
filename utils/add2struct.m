function [newStruct] = add2struct(oldStruct,struct2add)
%ADD2STRUCT  Add fields from one struct array to another.
%   NEWSTRUCT = ADD2STRUCT(OLDSTRUCT,STRUCT2ADD)

newStruct = oldStruct;

fieldns = fieldnames(struct2add);
for f = 1:length(fieldns)
    fieldname = fieldns{f};
    newStruct.(fieldname) = struct2add.(fieldname);
end
