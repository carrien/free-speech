function [newarg1,newarg2] = samelen(arg1,arg2)
%SAMELEN  Make two vectors the same length (the smaller of the two).
%   SAMELEN(ARG1,ARG2) shortens the length of the longer vector to match
%   the length of the shorter.  In the special case in which one of the
%   arguments is a scalar, this value is replicated to form a vector the
%   length of the other argument.

if isscalar(arg1)
    newarg1 = arg1*ones(size(arg2));
    newarg2 = arg2;
    return
elseif isscalar(arg2)
    newarg2 = arg2*ones(size(arg1));
    newarg1 = arg1;
    return
else
    minlen = min(length(arg1),length(arg2));
    newarg1 = arg1(1:minlen);
    newarg2 = arg2(1:minlen);
end