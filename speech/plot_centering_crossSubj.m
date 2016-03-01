function [observations,subjects,conditions,dist_init,dist_mid,durs,s_durs,c_durs,observations_mean,conditions_mean] = plot_centering_crossSubj(dataPaths,ntile)

if ischar(dataPaths), dataPaths = {dataPaths}; end
if nargin < 2, ntile = 3; end

observations = [];
observations_mean = [];
dist_init = [];
dist_mid = [];
subjects = [];
conditions = [];
conditions_mean = [];

durs = [];
s_durs = [];
c_durs = [];

conds = {'quiet','noiseHalf','noiseFull'};
%conds = {'quiet','noiseFull'};

for s=1:length(dataPaths)
    load(fullfile(dataPaths{s},sprintf('centering_%dtile.mat',ntile)));
    %load(fullfile(getAcoustSubjPath(exptName,svec(s),subdir),'fdata_cond_E.mat'),'durdata');
    for c=1:length(conds)
        
        observations = [observations centering.(conds{c})];
        subjects = [subjects s*ones(1,length(centering.(conds{c})))];
        conditions = [conditions c*ones(1,length(centering.(conds{c})))];
        
        dist_init = [dist_init dists_init.(conds{c})];
        dist_mid = [dist_mid dists_mid.(conds{c})];

        observations_mean = [observations_mean centering_mean.(conds{c})];
        conditions_mean = [conditions_mean c*ones(1,length(centering_mean.(conds{c})))];
        
%        durs2use = [dataVals(and([dataVals.cond] == c,~[dataVals.bExcl])).dur];
%        durs2use = durdata.s.(conds{c});
        durs2use = dur.(conds{c});
        durs = [durs durs2use];
        s_durs = [s_durs s*ones(1,length(durs2use))];
        c_durs = [c_durs c*ones(1,length(durs2use))];

    end
end