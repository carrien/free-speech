function [samea,sameb] = samelen(a,b)

samea = a;
sameb = b;

if length(a) > length(b)
    samea = samea(1:length(b)); 
elseif length(a) > length(b)
    sameb = sameb(1:length(a));     
end