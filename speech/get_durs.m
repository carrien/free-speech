function [allDurs] = get_durs(exptName)

exptData = get_exptInfo(exptName);
snums = exptData.snums;

allDurs = [];

% for i=1:length(snums)
%     subjPath = getAcoustSubjPath(exptName,snums(i),'pert','formant_analysis');
%     load(fullfile(subjPath,'dataVals_medsplit.mat'));
%     durs = [dataVals.dur]';
%     allDurs = nancat(allDurs,durs);
% end

for i=1:length(snums)
    subjPath = getAcoustSubjPath(exptName,snums(i),'pert','formant_analysis');
    load(fullfile(subjPath,'dataVals_medsplit.mat'));
    for j=1:length(dataVals)
        durs(j) = dataVals(j).f0(end,1)-dataVals(j).f0(1,1);
    end
    allDurs = nancat(allDurs,durs');
    clear durs
end