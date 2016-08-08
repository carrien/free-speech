function [] = plot_centering(dataPaths,condtype,condinds,plotinds,ntile)
%PLOT_CENTERING  Plot vowel centering in center and peripheral trials.
%   PLOT_CENTERING reads formants from a subject's fdata file and plots
%   them with respect to the median at both the beginning (first50ms) and
%   middle (mid50p) of each trial. PLOTINDS determines which type of view
%   is plotted: 1 for normalized init->mid, 2 for non-normalized init->mid,
%   and/or 3 for periph->median.
%
%CN 8/2013

if nargin < 1 || isempty(dataPaths), dataPaths = cd; end
if ischar(dataPaths), dataPaths = {dataPaths}; end
if nargin < 2 || isempty(condtype), condtype = 'vowel'; end
if nargin < 3 || isempty(condinds), condinds = [1 2 3]; end
if nargin < 4 || isempty(plotinds), plotinds = [1 2]; end
if nargin < 5 || isempty(ntile), ntile = 5; end

for s=1:length(dataPaths)
    load(fullfile(dataPaths{s},sprintf('fdata_%s.mat',condtype)));
    conds = fieldnames(fmtdata.mels);
    
    for cnd = condinds
        c = conds{cnd}; % current condition name
        first = fmtdata.mels.(c).first50ms;
        mid = fmtdata.mels.(c).mid50p;
        
        if ntile < 3
            ntiles = median(first.dist);
        else
            ntiles = quantile(first.dist,ntile-1);
        end
        cen = first.dist < ntiles(1); % or meddist
        pph = first.dist > ntiles(end);
        fpph = find(pph);
        fcen = find(cen);
        
        %% init to mid, normalized
        if sum(plotinds == 1)
            figure;
            subplot(1,2,1)
            
            initf1norm = first.rawavg.f1 - first.med.f1;
            initf2norm = first.rawavg.f2 - first.med.f2;
            midf1norm = mid.rawavg.f1 - mid.med.f1;
            midf2norm = mid.rawavg.f2 - mid.med.f2;
            
            dinit.pph = nanmean(sqrt(initf1norm(pph).^2 + initf2norm(pph).^2)); % average distance to median (init)
            dmid.pph = nanmean(sqrt(midf1norm(pph).^2 + midf2norm(pph).^2));    % average distance to median (mid)

            dinit.cen = nanmean(sqrt(initf1norm(cen).^2 + initf2norm(cen).^2));
            dmid.cen = nanmean(sqrt(midf1norm(cen).^2 + midf2norm(cen).^2));


            midd = setdiff(1:length(initf1norm),union(cen,pph));
            dinit.midd = nanmean(sqrt(initf1norm(midd).^2 + initf2norm(midd).^2));
            dmid.midd = nanmean(sqrt(midf1norm(midd).^2 + midf2norm(midd).^2));
            % simple: just store init and final dists (subtract to get
            % centering, and also use them to check for changes in
            % dispersion)
            dists_init.(c).pph = sqrt(initf1norm(pph).^2 + initf2norm(pph).^2);
            dists_mid.(c).pph = sqrt(midf1norm(pph).^2 + midf2norm(pph).^2);
            dists_init.(c).cen = sqrt(initf1norm(cen).^2 + initf2norm(cen).^2);
            dists_mid.(c).cen = sqrt(midf1norm(cen).^2 + midf2norm(cen).^2);
            dists_init.(c).midd = sqrt(initf1norm(midd).^2 + initf2norm(midd).^2);
            dists_mid.(c).midd = sqrt(midf1norm(midd).^2 + midf2norm(midd).^2);
            % store centering values
            centering_mean.(c).pph = dinit.pph - dmid.pph;
            centering_mean.(c).cen = dinit.cen - dmid.cen;
            centering_mean.(c).midd = dinit.midd - dmid.midd;
            centering.(c).pph = dists_init.(c).pph - dists_mid.(c).pph;
            centering.(c).cen = dists_init.(c).cen - dists_mid.(c).cen;
            centering.(c).midd = dists_init.(c).midd - dists_mid.(c).midd;
            % store duration values (periph only)
            if exist('durdata','var')
                dur.(c).pph = durdata.s.(c)(pph);
                dur.(c).cen = durdata.s.(c)(cen);
                dur.(c).midd = durdata.s.(c)(midd);
            else
                dur = [];
            end
            % formant movement in euclidean space
            euclmove = sqrt((mid.rawavg.f1-first.rawavg.f1).^2 + (mid.rawavg.f2-first.rawavg.f2).^2);
            eucl.(c).pph = euclmove(pph);
            eucl.(c).cen = euclmove(cen);
            eucl.(c).midd = euclmove(midd);
                        
            plot(0,0,'ko')
            hold on;
            plot(initf1norm(pph),initf2norm(pph),'ro')
            rectangle('Position',[-dinit.pph,-dinit.pph,dinit.pph*2,dinit.pph*2],'Curvature',[1,1],'LineStyle','--')
            plot(midf1norm(pph),midf2norm(pph),'k.')
            rectangle('Position',[-dmid.pph,-dmid.pph,dmid.pph*2,dmid.pph*2],'Curvature',[1,1])
            
            for i=1:length(fpph)
                plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
                    [initf2norm(fpph(i)) midf2norm(fpph(i))], 'r-')
            end
            xlabel('norm F1 (mels)')
            ylabel('norm F2 (mels)')
            box off
            axis square
            ax = axis;
            
            subplot(1,2,2)
            plot(0,0,'ko')
            hold on;
            plot(initf1norm(cen),initf2norm(cen),'go')
            rectangle('Position',[-dinit.cen,-dinit.cen,dinit.cen*2,dinit.cen*2],'Curvature',[1,1],'LineStyle','--')
            plot(midf1norm(cen),midf2norm(cen),'k.')
            rectangle('Position',[-dmid.cen,-dmid.cen,dmid.cen*2,dmid.cen*2],'Curvature',[1,1])
            for i=1:length(fcen)
                plot([initf1norm(fcen(i)) midf1norm(fcen(i))], ...
                    [initf2norm(fcen(i)) midf2norm(fcen(i))], 'g-')
            end
            xlabel('norm F1 (mels)')
            ylabel('norm F2 (mels)')
            box off
            axis square
            axis(ax);
            
            set(gcf,'Position',[265 355 820 299],'Name',sprintf('subjind %d %s %d (%s)',s,condtype,cnd,c))
        end
        
        %% init to mid, non-normalized
        if sum(plotinds == 2)
            figure;
            subplot(1,2,1)
            
            initf1 = first.rawavg.f1;
            initf1med = first.med.f1;
            initf2 = first.rawavg.f2;
            initf2med = first.med.f2;
            
            midf1 = mid.rawavg.f1;
            midf1med = mid.med.f1;
            midf2 = mid.rawavg.f2;
            midf2med = mid.med.f2;
            
            initf1norm = initf1 - initf1med;
            initf2norm = initf2 - initf2med;
            midf1norm = midf1 - midf1med;
            midf2norm = midf2 - midf2med;
            
            dinit.pph = nanmean(sqrt(initf1norm(pph).^2 + initf2norm(pph).^2));
            dmid.pph = nanmean(sqrt(midf1norm(pph).^2 + midf2norm(pph).^2));
            
            dinit.cen = nanmean(sqrt(initf1norm(cen).^2 + initf2norm(cen).^2));
            dmid.cen = nanmean(sqrt(midf1norm(cen).^2 + midf2norm(cen).^2));
            
            % plot per
            mycolor = 'b';
            plot(initf1med,initf2med,'*','Color',mycolor)
            hold on;
            plot(midf1med,midf2med,'*','Color',mycolor)
            plot(initf1(pph),initf2(pph),'o','Color',mycolor)
            rectangle('Position',[initf1med-dinit.pph,initf2med-dinit.pph,dinit.pph*2,dinit.pph*2],'Curvature',[1,1],'LineStyle','--','EdgeColor',mycolor)
            plot(midf1(pph),midf2(pph),'.','Color',mycolor)
            rectangle('Position',[midf1med-dmid.pph,midf2med-dmid.pph,dmid.pph*2,dmid.pph*2],'Curvature',[1,1],'EdgeColor',mycolor)
            
            for i=1:length(fpph)
                plot([initf1(fpph(i)) midf1(fpph(i))],[initf2(fpph(i)) midf2(fpph(i))], '-','Color',mycolor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            axis square
            ax = axis;
            
            % plot cen
            subplot(1,2,2)
            plot(initf1med,initf2med,'*','Color',mycolor)
            hold on;
            plot(midf1med,midf2med,'*','Color',mycolor)
            plot(initf1(cen),initf2(cen),'o','Color',mycolor)
            rectangle('Position',[initf1med-dinit.cen,initf2med-dinit.cen,dinit.cen*2,dinit.cen*2],'Curvature',[1,1],'LineStyle','--','EdgeColor',mycolor)
            plot(midf1(cen),midf2(cen),'.','Color',mycolor)
            rectangle('Position',[midf1med-dmid.cen,midf2med-dmid.cen,dmid.cen*2,dmid.cen*2],'Curvature',[1,1],'EdgeColor',mycolor)
            for i=1:length(fcen)
                plot([initf1(fcen(i)) midf1(fcen(i))],[initf2(fcen(i)) midf2(fcen(i))], '-','Color',mycolor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            axis square
            axis(ax);
            
            set(gcf,'Position',[265 355 820 299],'Name',sprintf('subjind %d %s %d (%s)',s,condtype,cnd,c))
        end
        
        %% periph to median
        if sum(plotinds == 3)
            
            figure;
            subplot(1,2,1)
            plot(first.rawavg.f1,first.rawavg.f2,'k.')
            hold on;
            plot(first.med.f1,first.med.f2,'ko')
            plot(first.rawavg.f1(cen),first.rawavg.f2(cen),'g.')
            plot(first.rawavg.f1(pph),first.rawavg.f2(pph),'r.')
            for i=1:length(fpph)
                plot([first.rawavg.f1(fpph(i)) first.med.f1], ...
                    [first.rawavg.f2(fpph(i)) first.med.f2], 'r--')
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            %axis([650 900 1410 1580])
            %set(gca,'YTick',1420:40:1580)
            
            subplot(1,2,2)
            plot(mid.rawavg.f1,mid.rawavg.f2,'k.')
            hold on;
            plot(mid.med.f1,mid.med.f2,'ko')
            plot(mid.rawavg.f1(cen),mid.rawavg.f2(cen),'g.')
            plot(mid.rawavg.f1(pph),mid.rawavg.f2(pph),'r.')
            for i=1:length(fpph)
                plot([mid.rawavg.f1(fpph(i)) mid.med.f1], ...
                    [mid.rawavg.f2(fpph(i)) mid.med.f2], 'r--')
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            %axis([650 900 1410 1580])
            set(gca,'YTick',1420:40:1580)
            set(gcf,'Position',[265 355 820 299])
        end
        
        %% init to mid, normalized, all subj overlaid
        if sum(plotinds == 4)
            if ~exist('dinit_all','var'), dinit_all = []; dmid_all = []; end
            if ~exist('h','var'), h = figure; end
            dinit_all = [dinit_all dinit.pph];
            dmid_all = [dmid_all dmid.pph];
            figure(h)
            plot(initf1norm(pph),initf2norm(pph),'ro')
            hold on;
            plot(midf1norm(pph),midf2norm(pph),'k.')
            for i=1:length(fpph)
                plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
                    [initf2norm(fpph(i)) midf2norm(fpph(i))], 'm-')
            end
            
        end
        
    end
    
    % save centering info per subject
    centfilename = fullfile(dataPaths{s},sprintf('centering_cvp_%dtile.mat',ntile));
    bSave = savecheck(centfilename);
    if bSave
        save(centfilename,'centering','centering_mean','dists_init','dists_mid','dur','eucl');
    end
    
end

    if sum(plotinds == 4)
        di = nanmean(dinit_all);
        dm = nanmean(dmid_all);
        figure(h);
        plot(0,0,'ko')
        hold on;
        rectangle('Position',[-di,-di,di*2,di*2],'Curvature',[1,1],'LineStyle','--')
        rectangle('Position',[-dm,-dm,dm*2,dm*2],'Curvature',[1,1])
        xlabel('norm F1 (mels)')
        ylabel('norm F2 (mels)')
        box off
        axis square
    end

