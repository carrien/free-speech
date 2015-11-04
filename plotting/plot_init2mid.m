function [ ] = plot_init2mid(exptName,svec,subdirname,condtype,condinds,plotinds,mycolor)
%PLOT_INIT2MID  Plot line from beginning to midpoint for all trials.
%   PLOT_INIT2MID reads formants from a subject's fdata file and plots ALL
%   TRIALS with respect to the median at both the beginning (first50ms) and
%   missle (mid50p) of each trial. (c.f. PLOT_CENTERING, which only plots
%   peripheral and center trials.)

if nargin < 3, subdirname = []; end
if nargin < 4 || isempty(condtype), condtype = 'vowel'; end
if nargin < 5 || isempty(condinds), condinds = [1 2 3]; end
if nargin < 6 || isempty(plotinds), plotinds = [1 2]; end
if nargin < 7 || isempty(mycolor), mycolor = 'b'; end

for s=1:length(svec)
    snum = svec(s);
    load(fullfile(getAcoustSubjPath(exptName,snum,subdirname),sprintf('fdata_%s.mat',condtype)));
    conds = fieldnames(fmtdata.mels);
    
    for v = condinds
        first50ms = fmtdata.mels.(conds{v}).first50ms;
        mid50p = fmtdata.mels.(conds{v}).mid50p;
             
        %% init to mid, normalized
        if sum(plotinds == 1)
            figure;
            
            initf1norm = first50ms.rawavg.f1 - first50ms.med.f1;
            initf2norm = first50ms.rawavg.f2 - first50ms.med.f2;
            midf1norm = mid50p.rawavg.f1 - mid50p.med.f1;
            midf2norm = mid50p.rawavg.f2 - mid50p.med.f2;
            
            dinit = nanmean(sqrt(initf1norm.^2 + initf2norm.^2));
            dmid = nanmean(sqrt(midf1norm.^2 + midf2norm.^2));
                        
            plot(0,0,'ko')
            hold on;
            plot(initf1norm,initf2norm,'ro')
            rectangle('Position',[-dinit,-dinit,dinit*2,dinit*2],'Curvature',[1,1],'LineStyle','--')
            plot(midf1norm,midf2norm,'k.')
            rectangle('Position',[-dmid,-dmid,dmid*2,dmid*2],'Curvature',[1,1])
            
            for i=1:length(initf1norm)
                plot([initf1norm(i) midf1norm(i)],[initf2norm(i) midf2norm(i)], 'r-')
            end
            xlabel('norm F1 (mels)')
            ylabel('norm F2 (mels)')
            box off
            axis square
            ax = axis;
            
            set(gcf,'Position',[265  139   540   515],'Name',sprintf('subj %d %s %d (%s)',snum,condtype,v,conds{v}))
        end
        
        %% init to mid, non-normalized
        if sum(plotinds == 2)
            figure;
            
            initf1 = first50ms.rawavg.f1;
            initf1med = first50ms.med.f1;
            initf2 = first50ms.rawavg.f2;
            initf2med = first50ms.med.f2;
            
            midf1 = mid50p.rawavg.f1;
            midf1med = mid50p.med.f1;
            midf2 = mid50p.rawavg.f2;
            midf2med = mid50p.med.f2;
            
            initf1norm = initf1 - initf1med;
            initf2norm = initf2 - initf2med;
            midf1norm = midf1 - midf1med;
            midf2norm = midf2 - midf2med;

            dinit = nanmean(sqrt(initf1norm.^2 + initf2norm.^2));
            dmid = nanmean(sqrt(midf1norm.^2 + midf2norm.^2));
                        
            % plot all trials
            plot(initf1med,initf2med,'*','Color',mycolor)
            hold on;
            plot(midf1med,midf2med,'*','Color',mycolor)
            plot(initf1,initf2,'o','Color',mycolor)
            rectangle('Position',[initf1med-dinit,initf2med-dinit,dinit*2,dinit*2],'Curvature',[1,1],'LineStyle','--','EdgeColor',mycolor)
            plot(midf1,midf2,'.','Color',mycolor)
            rectangle('Position',[midf1med-dmid,midf2med-dmid,dmid*2,dmid*2],'Curvature',[1,1],'EdgeColor',mycolor)
            
            for i=1:length(initf1)
                plot([initf1(i) midf1(i)],[initf2(i) midf2(i)], '-','Color',mycolor)
            end
            xlabel('F1 (mels)')
            ylabel('F2 (mels)')
            box off
            axis square
            ax = axis;
                        
            set(gcf,'Position',[265  139   540   515],'Name',sprintf('subj %d %s %d (%s)',snum,condtype,v,conds{v}))
        end
        
        %% periph to median
        if sum(plotinds == 3)
            
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

end

