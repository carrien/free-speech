function [s] = set_missingField(s,fieldname,value,bPrint)
%SET_MISSINGFIELD  Set fieldname in structure if it is not defined.

if nargin < 4 || isempty(bPrint), bPrint = 1; end

if ~isfield(s,fieldname)
    s.(fieldname) = value;
    if bPrint
        fprintf('Setting default %s\n',fieldname)
    end
end
