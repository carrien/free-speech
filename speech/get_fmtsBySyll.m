function [f1,f2] = get_fmtsBySyll(audevnt)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

f1 = []; f2 = [];

for i=1:length(audevnt)
    syllname = audevnt(i).Note3(1:end-1);
    startind = round(audevnt(i).StartTime2*audevnt(i).fs);
    stopind = round(audevnt(i).StopTime2*audevnt(i).fs);
    f1trace = audevnt(i).Acoustic_Data(startind:stopind,2);
    f2trace = audevnt(i).Acoustic_Data(startind:stopind,3);
    if ~isfield(f1,syllname)
        f1.(syllname) = f1trace;
        f2.(syllname) = f2trace;
    else
        f1.(syllname) = nancat(f1.(syllname),f1trace);
        f2.(syllname) = nancat(f2.(syllname),f2trace);
    end
end