function meandurs = get_meandur(exptName,svec)

meandurs = zeros(1,length(svec));
for sidx = 1:length(svec)
    snum = svec(sidx);
    load(fullfile(getAcoustSubjPath(exptName,snum),'dataVals.mat'))
    meandurs(sidx) = mean([dataVals.dur]);
end