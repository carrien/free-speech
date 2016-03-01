function [observations,subjects,conditions,tts,euclmov,dist_init,dist_mid,durs,s_durs,c_durs,observations_mean,conditions_mean] = plot_centering_crossSubj(dataPaths,ntile)

if ischar(dataPaths), dataPaths = {dataPaths}; end
if nargin < 2, ntile = 3; end

observations = [];
observations_mean = [];
dist_init = [];
dist_mid = [];
subjects = [];
conditions = [];
conditions_mean = [];
tts = [];
euclmov = [];

durs = [];
s_durs = [];
c_durs = [];

conds = {'quiet','noiseHalf','noiseFull'};
%conds = {'quiet','noiseFull'};

trialtypes = {'pph','cen','midd'};

for s=1:length(dataPaths)
    load(fullfile(dataPaths{s},sprintf('centering_cvp_%dtile.mat',ntile)));
    %load(fullfile(getAcoustSubjPath(exptName,svec(s),subdir),'fdata_cond_E.mat'),'durdata');
    for c=1:length(conds)
        for tt=1:length(trialtypes)
            
            observations = [observations centering.(conds{c}).(trialtypes{tt})];
            subjects = [subjects s*ones(1,length(centering.(conds{c}).(trialtypes{tt})))];
            conditions = [conditions c*ones(1,length(centering.(conds{c}).(trialtypes{tt})))];
            tts = [tts tt*ones(1,length(centering.(conds{c}).(trialtypes{tt})))];
            
            dist_init = [dist_init dists_init.(conds{c}).(trialtypes{tt})];
            dist_mid = [dist_mid dists_mid.(conds{c}).(trialtypes{tt})];
            
            observations_mean = [observations_mean centering_mean.(conds{c}).(trialtypes{tt})];
            conditions_mean = [conditions_mean c*ones(1,length(centering_mean.(conds{c}).(trialtypes{tt})))];
            
            euclmov = [euclmov eucl.(conds{c}).(trialtypes{tt})];
            
            %        durs2use = [dataVals(and([dataVals.cond] == c,~[dataVals.bExcl])).dur];
            %        durs2use = durdata.s.(conds{c});
            durs2use = dur.(conds{c}).(trialtypes{tt});
            durs = [durs durs2use];
            s_durs = [s_durs s*ones(1,length(durs2use))];
            c_durs = [c_durs c*ones(1,length(durs2use))];
            
        end

    end
end