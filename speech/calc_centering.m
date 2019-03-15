function [p,t,stats] = calc_centering(dataPaths)
%CALC_CENTERING  Calculate centering from vowel formant data.
%   CALC_CENTERING(DATAPATHS) loads data (fdata_vowel.mat files) from each
%   folder in the cell array DATAPATHS, calculates various values (such as
%   centering, time-reversed centering, anticentering, etc.) and adds the
%   values to arrays suitable for input to the anovan function.

avgfn = {'first50ms','mid50p'};
centering = []; group = [];
anticentering = []; groupanti = [];
dists = []; groupdists = [];
logdists = []; grouplogdists = [];
distdiffs = []; groupdistdiffs = [];
f0s = []; groupf0s = [];

means.centering = [];
means.centering_rev = [];
means.anticentering = [];
means.anticentering_rev = [];
means.dinit = [];
means.dmid = [];

for s=1:length(dataPaths)
    dP = dataPaths{s};
    load(fullfile(dP,'fdata_vowel'));
    
    vowels = fieldnames(fmtdata.mels);
    
    for v=1:length(vowels)
        vow = vowels{v};
        
        %% get data for both time windows
        for a = 1:length(avgfn)
            avg = avgfn{a}; % use this time window to determine centrality
            
            % center data (closest quartile)
            inds_c = find(fmtdata.mels.(vow).(avg).dist < fmtdata.mels.(vow).(avg).quardist(1));
            dist.(avg).center.first = fmtdata.mels.(vow).first50ms.dist(inds_c);
            dist.(avg).center.mid = fmtdata.mels.(vow).mid50p.dist(inds_c);
            
            % periph data (farthest quartile)
            inds_p = find(fmtdata.mels.(vow).(avg).dist > fmtdata.mels.(vow).(avg).quardist(end));
            dist.(avg).periph.first = fmtdata.mels.(vow).first50ms.dist(inds_p);
            dist.(avg).periph.mid = fmtdata.mels.(vow).mid50p.dist(inds_p);
        end
        
        %% calculate centering and add to variables for anovan
        % peripheral centering, original (group 1)
        data2add = dist.first50ms.periph.first - dist.first50ms.periph.mid;
        [centering,group] = add2anovars(centering,data2add',group,s,v,1);
        means.centering = [means.centering mean(data2add)];
        % peripheral centering, time-window reversed (group 2)
        data2add = dist.mid50p.periph.mid - dist.mid50p.periph.first;
        [centering,group] = add2anovars(centering,data2add',group,s,v,2);
        means.centering_rev = [means.centering_rev mean(data2add)];
        
        % central anti-centering, original (group 1)
        data2add = dist.first50ms.center.first - dist.first50ms.center.mid;
        [anticentering,groupanti] = add2anovars(anticentering,data2add',groupanti,s,v,1);
        means.anticentering = [means.anticentering mean(data2add)];
        % central anti-centering, time-window reversed (group 2)
        data2add = dist.mid50p.center.mid - dist.mid50p.center.first;
        [anticentering,groupanti] = add2anovars(anticentering,data2add',groupanti,s,v,2);
        means.anticentering_rev = [means.anticentering_rev mean(data2add)];
        
        % d_init, all trials (group 1)
        data2add = fmtdata.mels.(vow).first50ms.dist;
        [dists,groupdists] = add2anovars(dists,data2add',groupdists,s,v,1);
        means.dinit = [means.dinit mean(data2add)];
        % d_mid, all trials (group 2)
        data2add = fmtdata.mels.(vow).mid50p.dist;
        [dists,groupdists] = add2anovars(dists,data2add',groupdists,s,v,2);
        means.dmid = [means.dmid mean(data2add)];
        
        % LOG d_init, all trials (group 1)
        data2add = log(fmtdata.mels.(vow).first50ms.dist);
        [logdists,grouplogdists] = add2anovars(logdists,data2add',grouplogdists,s,v,1);
        % LOG d_mid, all trials (group 2)
        data2add = log(fmtdata.mels.(vow).mid50p.dist);
        [logdists,grouplogdists] = add2anovars(logdists,data2add',grouplogdists,s,v,2);
        
        % d init-mid, all trials
        data2add = fmtdata.mels.(vow).first50ms.dist - fmtdata.mels.(vow).mid50p.dist;
        [distdiffs,groupdistdiffs] = add2anovars(distdiffs,data2add',groupdistdiffs,s,v);
        
        % f0 init, all trials (group 1)
        data2add = f0data.mels.(vow).first50ms.rawavg.f0;
        [f0s,groupf0s] = add2anovars(f0s,data2add',groupf0s,s,v,1);
        % f0 mid, all trials (group 2)
        data2add = f0data.mels.(vow).mid50p.rawavg.f0;
        [f0s,groupf0s] = add2anovars(f0s,data2add',groupf0s,s,v,2);        
        
    end
    
end

%% stats: compare magnitudes of centering and time-reversed centering
[p,t,stats] = anovan(centering,group,'random',1);
figure; multcompare(stats,'dimension',[1 3]);