function [f1,f2] = gen_F1F2matrix(exptName,snum,subdirname)
fs = 0.0030;

load(fullfile(getAcoustSubjPath(exptName,snum,subdirname),'dataVals.mat'));
f1 = []; f2 = [];
for i=1:length(dataVals)
    cond = dataVals(i).cond;
    if ~dataVals(i).bExcl
        if isempty(f1) || length(f1) < cond
            f1{cond} = dataVals(i).f1;
            f2{cond} = dataVals(i).f2;
        else
            f1{cond} = nancat(f1{cond},dataVals(i).f1);
            f2{cond} = nancat(f2{cond},dataVals(i).f2);
        end
    end
end

for c=1:length(f1)
    for t=1:size(f1{c},1)
        f1t = f1{c}(t,:); f1t = f1t(~isnan(f1t));
        f2t = f2{c}(t,:); f2t = f2t(~isnan(f2t));
        if length(f1t) > 1
            [~,a] = FitEllipse(f1t,f2t); %#ok<*SAGROW>
        end
        area{c}(t) = a;
    end
end

figure;plot(0:fs:(length(area{1})-1)*fs,area{1},'-')
hold on;
plot(0:fs:(length(area{2})-1)*fs,area{2},'--')
plot(0:fs:(length(area{3})-1)*fs,area{3},':')
xlabel('t (s)')
title('Area of fuzzball')