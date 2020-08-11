function [T] = get_durTable(dataPaths)
%GET_DURTABLE  Get table with duration by trial.
%   T = GET_DURTABLE(DATAPATHS)

if ischar(dataPaths)
    dataPaths = {dataPaths};
end
nsubj = length(dataPaths);

stab = cell(1,nsubj);
for dP = 1:nsubj
    dataPath = dataPaths{dP};
    load(fullfile(dataPath,'expt.mat'),'expt');
    load(fullfile(dataPath,'dataVals.mat'),'dataVals');
    
    goodInds = ~[dataVals.bExcl];
    dat.dur = [dataVals(goodInds).dur]';
    
    trialnums = [dataVals(goodInds).token];
    fact.snum = dP;
    fact.trialnum = trialnums;
    fact.cond = expt.listConds(trialnums);
    fact.word = expt.listWords(trialnums);
    
    stab{dP} = get_datatable(dat,fact);
end

T = vertcat(stab{:});
