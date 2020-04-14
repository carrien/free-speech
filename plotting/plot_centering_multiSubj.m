function [ ] = plot_centering_multiSubj(dataPaths,condtype,condnames,ntile,bOneFig)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 || isempty(dataPaths), dataPaths = cd; end
if ischar(dataPaths), dataPaths = {dataPaths}; end
if nargin < 2 || isempty(condtype), condtype = 'vowel'; end
if nargin < 3 || isempty(condnames), condnames = {'i' 'E' 'ae'}; end
if nargin < 4 || isempty(ntile), ntile = 5; end
if nargin < 5 || isempty(bOneFig), bOneFig = 1; end

axmax = 0;

for s=1:length(dataPaths)
    load(fullfile(dataPaths{s},sprintf('fdata_%s.mat',condtype)));
    
    for c = 1:length(condnames)
        cnd = condnames{c}; % current condition name
        
        if ~isfield(fmtdata.mels,cnd) || ~isfield(fmtdata.mels.(cnd),'first50ms')
            continue % skip if vowel data doesn't exist
        end
        
        first = fmtdata.mels.(cnd).first50ms;
        mid = fmtdata.mels.(cnd).mid50p;
        
        if ntile < 3
            ntiles = median(first.dist);
        else
            ntiles = quantile(first.dist,ntile-1);
        end
        cen = first.dist < ntiles(1); % or meddist
        pph = first.dist > ntiles(end);
        fpph = find(pph);
        fcen = find(cen);
        
        %% calc init to mid, normalized
        if bOneFig
            subplot(length(condnames),length(dataPaths),(c-1)*length(dataPaths)+s)
        else
            figure;
        end
        
        initf1norm = first.rawavg.f1 - first.med.f1;
        initf2norm = first.rawavg.f2 - first.med.f2;
        midf1norm = mid.rawavg.f1 - mid.med.f1;
        midf2norm = mid.rawavg.f2 - mid.med.f2;
        
        dists_init_mean.pph = nanmean(sqrt(initf1norm(pph).^2 + initf2norm(pph).^2)); % average distance to median (init)
        dists_mid_mean.pph = nanmean(sqrt(midf1norm(pph).^2 + midf2norm(pph).^2));    % average distance to median (mid)
        
        midd = setdiff(1:length(initf1norm),union(cen,pph));
        
        % store init and final dists
        % (subtract to get centering & use to check for changes in dispersion)
        dists_init.(cnd).pph = sqrt(initf1norm(pph).^2 + initf2norm(pph).^2);
        dists_mid.(cnd).pph = sqrt(midf1norm(pph).^2 + midf2norm(pph).^2);
        dists_init.(cnd).cen = sqrt(initf1norm(cen).^2 + initf2norm(cen).^2);
        dists_mid.(cnd).cen = sqrt(midf1norm(cen).^2 + midf2norm(cen).^2);
        dists_init.(cnd).midd = sqrt(initf1norm(midd).^2 + initf2norm(midd).^2);
        dists_mid.(cnd).midd = sqrt(midf1norm(midd).^2 + midf2norm(midd).^2);
        
        nanmean(dists_init.(cnd).pph) == dists_init_mean.pph;
        nanmean(dists_mid.(cnd).pph) == dists_mid_mean.pph;
        
        % store centering values
        centering.(cnd).pph = dists_init.(cnd).pph - dists_mid.(cnd).pph;
        centering.(cnd).cen = dists_init.(cnd).cen - dists_mid.(cnd).cen;
        centering.(cnd).midd = dists_init.(cnd).midd - dists_mid.(cnd).midd;
        % store duration values (periph only)
        if exist('durdata','var')
            dur.(cnd).pph = durdata.s.(cnd)(pph);
            dur.(cnd).cen = durdata.s.(cnd)(cen);
            dur.(cnd).midd = durdata.s.(cnd)(midd);
        else
            dur = [];
        end
        % formant movement in euclidean space
        euclmove = sqrt((mid.rawavg.f1-first.rawavg.f1).^2 + (mid.rawavg.f2-first.rawavg.f2).^2);
        eucl.(cnd).pph = euclmove(pph);
        eucl.(cnd).cen = euclmove(cen);
        eucl.(cnd).midd = euclmove(midd);
        
        %% plot init to mid, normalized
        plot(0,0,'ko')
        hold on;
        plot(initf1norm(pph),initf2norm(pph),'ro')
        rectangle('Position',[-dists_init_mean.pph,-dists_init_mean.pph,dists_init_mean.pph*2,dists_init_mean.pph*2],'Curvature',[1,1],'LineStyle','--')
        plot(midf1norm(pph),midf2norm(pph),'k.')
        rectangle('Position',[-dists_mid_mean.pph,-dists_mid_mean.pph,dists_mid_mean.pph*2,dists_mid_mean.pph*2],'Curvature',[1,1])
        
        for i=1:length(fpph)
            plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
                [initf2norm(fpph(i)) midf2norm(fpph(i))], 'r-')
        end
        xlabel('norm F1 (mels)')
        ylabel('norm F2 (mels)')
        box off
        axis square
        if max(abs(axis)) > axmax
            axmax = max(abs(axis));
        end
        axis([-axmax axmax -axmax axmax])
        
    end
    
end

for sp = 1:length(condnames)*length(dataPaths)
    subplot(length(condnames),length(dataPaths),sp);
    axmax = 150;
    axis([-axmax axmax -axmax axmax]);
end
