function [] = plot_autocorr(exptName,snum,subdirname,anfunc)

if nargin < 4 || isempty(anfunc), anfunc = 'first50ms'; end

load(fullfile(getAcoustSubjPath(exptName,snum,subdirname),'fdata_cond.mat'));
fieldns = fieldnames(fmtdata.mels);
linestyles = {'-','--',':'};
maxlag = 5;

nfigs = getnfigs;
for fn=1:length(fieldns)
    f1 = fmtdata.mels.(fieldns{fn}).(anfunc).rawavg.f1;
    f2 = fmtdata.mels.(fieldns{fn}).(anfunc).rawavg.f2;
    f1n = f1 - nanmean(f1);
    f2n = f2 - nanmean(f2);
    f1diff = diff(f1); f1diffn = f1diff - nanmean(f1diff); f1diffn = f1diffn(~isnan(f1diffn));
    f2diff = diff(f2); f2diffn = f2diff - nanmean(f2diff); f2diffn = f2diffn(~isnan(f2diffn));
    
%     figure(nfigs+1);
%     [c,lags] = xcorr(f1n,maxlag,'coeff');
%     plot(lags,c,'b','LineStyle',linestyles{fn});
%     hold on;
%     title(sprintf('normalized f1, %s',anfunc))
%     set(gcf,'Position',[1300 800 1700 400]);
%     
%     figure(nfigs+2);
%     [c,lags] = xcorr(f2n,maxlag,'coeff');
%     plot(lags,c,'r','LineStyle',linestyles{fn});
%     hold on;
%     title(sprintf('normalized f2, %s',anfunc))
%     set(gcf,'Position',[1300 300 1700 400]);
%     
    figure(nfigs+1);
    [c,lags] = xcorr(f1diffn,maxlag,'coeff');
    plot(lags,c,'b','LineStyle',linestyles{fn});
    hold on;
    title(sprintf('normalized f1 diff, %s',anfunc))
    set(gcf,'Position',[1350 800 1700 400]);
    
    figure(nfigs+2);
    [c,lags] = xcorr(f2diffn,maxlag,'coeff');
    plot(lags,c,'r','LineStyle',linestyles{fn});
    hold on;
    title(sprintf('normalized f2 diff, %s',anfunc))
    set(gcf,'Position',[1350 300 1700 400]);
    
%     for l=0:20
%         for i=1:length(f1)-l
%             eucdist{l+1}(i) = sqrt((f1(i+l)-f1(i))^2 + (f2(i+l)-f2(i))^2);
%             f1dist{l+1}(i) = f1(i+l)-f1(i);
%             f2dist{l+1}(i) = f2(i+l)-f2(i);
%         end
%         eucdistmean(l+1) = nanmean(eucdist{l+1});
%         f1distmean(l+1) = nanmean(f1dist{l+1});
%         f2distmean(l+1) = nanmean(f2dist{l+1});
%         
% %         figure(nfigs+5+l+1);
% %         hold on;
% %         %[c,lags] = xcorr(f2diffn,maxlag,'coeff');
% %         plot(eucdist{l+1},'g','LineStyle',linestyles{fn});
% %         title(sprintf('Euclidean distance, lag %d',l))
% %         set(gcf,'Position',[1350 300 1700 400]);
%         
%     end 
%     figure(nfigs+1)
%     plot(0:length(eucdistmean)-1,eucdistmean,'g','LineStyle',linestyles{fn});
%     hold on;
%     title(sprintf('Euclidean distance, %s',anfunc))
%     xlabel('lag')
%     set(gcf,'Position', [360   388   422   310])
%     axis([0 20 0 90])
%     
%     figure(nfigs+2)
%     plot(0:length(f1distmean)-1,f1distmean,'b','LineStyle',linestyles{fn});
%     hold on;
%     title(sprintf('F1, %s',anfunc))
%     xlabel('lag')
%     set(gcf,'Position', [360   388   422   310])
%     axis([0 20 -40 40])
% 
%     figure(nfigs+3)
%     plot(0:length(f2distmean)-1,f2distmean,'r','LineStyle',linestyles{fn});
%     hold on;
%     title(sprintf('F2, %s',anfunc))
%     xlabel('lag')
%     set(gcf,'Position', [360   388   422   310])
%     axis([0 20 -40 40])

end