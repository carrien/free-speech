function [s] = set_missingFields(s,defaults,bPrint)
%SET_MISSINGFIELDS  Set fieldnames in structure if they are not defined.
%   S = SET_MISSINGFIELDS(S,DEFAULTS,BPRINT) copies the fields from the
%   struct array DEFAULTS to the struct array S unless they already exist
%   in S. BPRINT is a boolean that determines whether to print each missing
%   field to the screen.

if isempty(s), s = struct; end
if nargin < 3 || isempty(bPrint), bPrint = 1; end

snames = fieldnames(s);
dnames = fieldnames(defaults);
missingIdx = find(~ismember(dnames,snames));

for fn = 1:length(missingIdx)
    fieldname = dnames{missingIdx(fn)};
    s.(fieldname) = defaults.(fieldname);
    if bPrint
        fprintf('Setting default %s\n',fieldname)
    end
end
