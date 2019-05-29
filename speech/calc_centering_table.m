function [centering_table_pph,anti_table,centering_table_all] = calc_centering_table(basepath,subs,fdatafile)
%CALC_CENTERING  Calculate centering from vowel formant data.
%   CALC_CENTERING(DATAPATHS) loads data (default fdata_vowel.mat files if none specified) from each
%   folder in the cell array basepath/SUBS (subs is a cell array), calculates various values (such as
%   centering, time-reversed centering, anticentering, etc.) and adds the
%   values to arrays. These arrays are then transformed into a table. Each
%   row in the table represents one trial.

% basepath is where you'll find the subject's data
% subs is a cell array of subjects
% fdatafile is the filename where fdata is to be found.
% for example:
% centering_table = calc_centering_table('/Volumes/bits/projectdata',{'TMB'
%     'JL' 'CN' 'SB'},'someotherfdatafilename')

if nargin < 3 || isempty(fdatafile), fdatafile = 'fdata_vowel'; end

avgfn = {'first50ms','mid50p'};
centering = []; group = [];
anticentering = []; groupanti = [];
centering_rev = []; anticentering_rev = []; groupcentrev = []; groupantirev = [];
inidists = []; middists = []; groupinidists = []; groupmiddists = [];
f0s = []; groupf0s = []; f0s_rev = []; groupf0srev = [];

means.centering = [];
means.centering_rev = [];
means.anticentering = [];
means.anticentering_rev = [];
means.dinit = [];
means.dmid = [];

dataPaths = fullfile(basepath, subs); % you'll need "subs" later to get the subject name.

for s=1:length(dataPaths)
    dP = dataPaths{s};
    load(fullfile(dP,fdatafile));
    
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
        [centering,group] = add2anovars(centering,data2add',group,s,v);
        
%           means.centering = [means.centering mean(data2add)];
%        % peripheral centering, time-window reversed (group 2)
         data2add = dist.mid50p.periph.mid - dist.mid50p.periph.first;
         [centering_rev,groupcentrev] = add2anovars(centering_rev,data2add',groupcentrev,s,v);
%         means.centering_rev = [means.centering_rev mean(data2add)];
%         
%         % central anti-centering, original (group 1)
         data2add = dist.first50ms.center.first - dist.first50ms.center.mid;
         [anticentering,groupanti] = add2anovars(anticentering,data2add',groupanti,s,v);
%         means.anticentering = [means.anticentering mean(data2add)];
%         % central anti-centering, time-window reversed (group 2)
         data2add = dist.mid50p.center.mid - dist.mid50p.center.first;
         [anticentering_rev,groupantirev] = add2anovars(anticentering_rev,data2add',groupantirev,s,v);
%         means.anticentering_rev = [means.anticentering_rev mean(data2add)];
%         
%         % d_init, all trials (group 1)
         data2add = fmtdata.mels.(vow).first50ms.dist;
         [inidists,groupinidists] = add2anovars(inidists,data2add',groupinidists,s,v);
%         means.dinit = [means.dinit mean(data2add)];
%         % d_mid, all trials (group 2)
         data2add = fmtdata.mels.(vow).mid50p.dist;
         [middists,groupmiddists] = add2anovars(middists,data2add',groupmiddists,s,v);
%         means.dmid = [means.dmid mean(data2add)];
%                  
%         % f0 init, all trials (group 1)
         data2add = f0data.mels.(vow).first50ms.rawavg.f0;
         [f0s,groupf0s] = add2anovars(f0s,data2add',groupf0s,s,v);
%         % f0 mid, all trials (group 2)
         data2add = f0data.mels.(vow).mid50p.rawavg.f0;
         [f0s_rev,groupf0srev] = add2anovars(f0s_rev,data2add',groupf0srev,s,v);        
%         
    end
    
end

subindices = group{1};
subj = {subs{subindices}}';
vowelindices = group{2};
vowel = {vowels{vowelindices}}';

centering_table_pph = table(centering, centering_rev, subj,vowel);

% anticentering

antisubindices = groupanti{1};
subj = {subs{antisubindices}}';
antivowelindices = groupanti{2};
vowel = {vowels{antivowelindices}}';

anti_table = table(anticentering, anticentering_rev, subj, vowel); % anti-centering uses DIFFERENT TRIALS from peripheral centering

allsubsinds = groupinidists{1};
subj = {subs{allsubsinds}}';
allvowelinds = groupinidists{2};
vowel = {vowels{allvowelinds}}';

loginidists = log(inidists);
logmiddists = log(middists);
trialdists = inidists-middists; % acoustic distance traveled during one trial

centering_table_all = table(subj, vowel, trialdists, inidists, middists, loginidists, logmiddists, f0s, f0s_rev); 
