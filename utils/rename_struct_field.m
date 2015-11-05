function [mystruct] = rename_struct_field(mystruct,oldfield,newfield)
%RENAME_STRUCT_FIELD  Rename field of a struct array.
%   RENAME_STRUCT_FIELD(MYSTRUCT,OLDFIELD,NEWFIELD) renames the field
%   in the string OLDFIELD to the name in the string NEWFIELD and returns
%   the renamed MYSTRUCT. Only works for struct fields one level deep.

[mystruct.(newfield)] = mystruct.(oldfield);
mystruct = rmfield(mystruct,oldfield);