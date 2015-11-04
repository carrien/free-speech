function [] = plot_vowelspaceByCond(exptName,snum,subdirname,condtype)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

load(fullfile(getAcoustSubjPath(exptName,snum,subdirname),sprintf('fdata_%s.mat',condtype)));
conds = fieldnames(fmtdata.mels);
anl = {'first50ms','mid50p'};
colors = setcolors;

for a = 1:length(anl)
    figure;
    for c = 1:length(conds)
        conddata = fmtdata.mels.(conds{c});
        f1 = conddata.(anl{a}).rawavg.f1;
        f2 = conddata.(anl{a}).rawavg.f2;
        plot(f1,f2,'.','Color',colors(c,:))
        hold on;
        ell = FitEllipse(f1,f2);
        plot(ell(:,1),ell(:,2),'Color',colors(c,:));
    end
    xlabel('F1 (mels)')
    ylabel('F2 (mels)')
    title(anl{a})
    legend(conds)
end