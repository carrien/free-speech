function [] = plot_centering_f0(exptName,svec,subdirname,condtype,condinds,plotinds,ntile)
%PLOT_CENTERING_F0  Plot pitch centering in center and peripheral trials.
%   PLOT_CENTERING_F0 reads pitches from a subject's fdata file and plots
%   them with respect to the median at both the beginning (first50ms) and
%   middle (mid50p) of each trial. PLOTINDS determines which type of view
%   is plotted: 1 for normalized init->mid, 2 for non-normalized init->mid,
%   and/or 3 for periph->median.
%
%CN 2/2014

if nargin < 3, subdirname = []; end
if nargin < 4 || isempty(condtype), condtype = 'cond'; end
if nargin < 5 || isempty(condinds), condinds = [1 2 3]; end
if nargin < 6 || isempty(plotinds), plotinds = [1 2]; end
if nargin < 7 || isempty(ntile), ntile = 5; end

for s=1:length(svec)
    snum = svec(s);
    load(fullfile(getAcoustSubjPath(exptName,snum,subdirname),sprintf('fdata_%s.mat',condtype)));
    conds = fieldnames(fmtdata.mels);
    
    for v = condinds
        first50ms = f0data.mels.(conds{v}).first50ms;
        mid50p = f0data.mels.(conds{v}).mid50p;
        
        if ntile < 3
            ntiles = median(first50ms.dist);
        else
            ntiles = quantile(first50ms.dist,ntile-1);
        end
        cen = first50ms.dist < ntiles(1); % or meddist
        pph = first50ms.dist > ntiles(end);
        fpph = find(pph);
        fcen = find(cen);
        
        initf0norm = first50ms.rawavg.f0 - first50ms.med.f0;
        midf0norm = mid50p.rawavg.f0 - mid50p.med.f0;
        
        dinit.pph = nanmean(abs(initf0norm(pph)));
        dmid.pph = nanmean(abs(midf0norm(pph)));
        dinit.cen = nanmean(abs(initf0norm(cen)));
        dmid.cen = nanmean(abs(midf0norm(cen)));
        
        %% init to mid, normalized, trial order
        if sum(plotinds == 1)
            
            figure;
            subplot(1,2,1)
            hold on;
            plot(initf0norm(pph),'ro')
            hline(dinit.pph,'k','--'); hline(-dinit.pph,'k','--');
            plot(midf0norm(pph),'k.')
            hline(dmid.pph,'k'); hline(-dmid.pph,'k');
            
            for i=1:length(fpph)
                plot([i i],[initf0norm(fpph(i)) midf0norm(fpph(i))], 'r-')
            end
            xlabel('trial #')
            ylabel('norm F0 (mels)')
            box off
            axis square
            ax = axis;
            hline(0,'r');
            
            subplot(1,2,2)
            hold on;
            plot(initf0norm(cen),'go')
            hline(dinit.cen,'k','--'); hline(-dinit.cen,'k','--');
            plot(midf0norm(cen),'k.')
            hline(dmid.cen,'k'); hline(-dmid.cen,'k');
            
            for i=1:length(fcen)
                plot([i i],[initf0norm(fcen(i)) midf0norm(fcen(i))], 'g-')
            end
            xlabel('trial #')
            ylabel('norm F0 (mels)')
            box off
            axis square
            axis(ax);
            hline(0,'g');
            
            set(gcf,'Position',[265 355 820 299],'Name',sprintf('subj %d %s %d (%s)',snum,condtype,v,conds{v}))
        end
        
        
        %% init to mid, normalized, ranked order
        if sum(plotinds == 2)
            
            [initf0norm_pph_sorted,pphSortInds] = sort(initf0norm(pph));
            midf0norm_pph = midf0norm(pph);
            midf0norm_pph_sorted = midf0norm_pph(pphSortInds);
            [initf0norm_cen_sorted,cenSortInds] = sort(initf0norm(cen));
            midf0norm_cen = midf0norm(cen);
            midf0norm_cen_sorted = midf0norm_cen(cenSortInds);
            
            figure;
            subplot(1,2,1)
            hold on;
            plot(initf0norm_pph_sorted,'ro')
            hline(dinit.pph,'k','--'); hline(-dinit.pph,'k','--');
            plot(midf0norm_pph_sorted,'k.')
            hline(dmid.pph,'k'); hline(-dmid.pph,'k');
            
            for i=1:length(initf0norm_pph_sorted)
                plot([i i],[initf0norm_pph_sorted(i) midf0norm_pph_sorted(i)], 'r-')
            end
            xlabel('trial #')
            ylabel('norm F0 (mels)')
            box off
            axis square
            ax = axis;
            hline(0,'r');
            
            subplot(1,2,2)
            hold on;
            plot(initf0norm_cen_sorted,'go')
            hline(dinit.cen,'k','--'); hline(-dinit.cen,'k','--');
            plot(midf0norm_cen_sorted,'k.')
            hline(dmid.cen,'k'); hline(-dmid.cen,'k');
            
            for i=1:length(initf0norm_cen_sorted)
                plot([i i],[initf0norm_cen_sorted(i) midf0norm_cen_sorted(i)], 'g-')
            end
            xlabel('trial (ranked)')
            ylabel('norm F0 (mels)')
            box off
            axis square
            axis(ax);
            hline(0,'g');
            
            set(gcf,'Position',[265 355 820 299],'Name',sprintf('subj %d %s %d (%s)',snum,condtype,v,conds{v}))
        end
        
        
        %% init to mid, non-normalized
        if sum(plotinds == 3)
            figure;
            subplot(1,2,1)
            
            initf0 = first50ms.rawavg.f0;
            initf0med = first50ms.med.f0;
            
            midf0 = mid50p.rawavg.f0;
            midf0med = mid50p.med.f0;
            
            initf0norm = initf0 - initf0med;
            midf0norm = midf0 - midf0med;
            
            dinit.pph = nanmean(abs(initf0norm(pph)));
            dmid.pph = nanmean(abs(midf0norm(pph)));
            
            dinit.cen = nanmean(abs(initf0norm(cen)));
            dmid.cen = nanmean(abs(midf0norm(cen)));
            
            % plot per
            mycolor = 'c';
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
            
            set(gcf,'Position',[265 355 820 299],'Name',sprintf('subj %d %s %d (%s)',snum,condtype,v,conds{v}))
        end
        
        %% periph to median
        if sum(plotinds == 4)
            
            figure;
            subplot(1,2,1)
            plot(first50ms.rawavg.f1,first50ms.rawavg.f2,'k.')
            hold on;
            plot(first50ms.med.f1,first50ms.med.f2,'ko')
            plot(first50ms.rawavg.f1(cen),first50ms.rawavg.f2(cen),'g.')
            plot(first50ms.rawavg.f1(pph),first50ms.rawavg.f2(pph),'r.')
            for i=1:length(fpph)
                plot([first50ms.rawavg.f1(fpph(i)) first50ms.med.f1], ...
                    [first50ms.rawavg.f2(fpph(i)) first50ms.med.f2], 'r--')
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            %axis([650 900 1410 1580])
            %set(gca,'YTick',1420:40:1580)
            
            subplot(1,2,2)
            plot(mid50p.rawavg.f1,mid50p.rawavg.f2,'k.')
            hold on;
            plot(mid50p.med.f1,mid50p.med.f2,'ko')
            plot(mid50p.rawavg.f1(cen),mid50p.rawavg.f2(cen),'g.')
            plot(mid50p.rawavg.f1(pph),mid50p.rawavg.f2(pph),'r.')
            for i=1:length(fpph)
                plot([mid50p.rawavg.f1(fpph(i)) mid50p.med.f1], ...
                    [mid50p.rawavg.f2(fpph(i)) mid50p.med.f2], 'r--')
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            %axis([650 900 1410 1580])
            set(gca,'YTick',1420:40:1580)
            set(gcf,'Position',[265 355 820 299])
        end
        
    end
end