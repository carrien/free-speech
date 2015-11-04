function [fmtdata] = calc_fmtdata(expt,dataVals)
% DEPRECATED?? Use calc_fdata instead.
% CALC_FMTDATA   Calculates mean/median formant data from dataVals object.

%fs = 250; % 1/stepsize aka 1/"Incr";add to dataVals
if strcmp(expt.name, 'mvSIS')
    fs = 250;
else
    fs = 333.3333;
end

% fmtdata: top level variable
freqscale = {'hz', 'mels'};     % f: frequency scales
vowels = expt.vowels;           % v: vowels
avgfn = {'mid50p', 'first50ms'};  % av: averging functions
analysis = {'rawavg' 'med', 'dist', 'meddist',...
    'center50', 'periph50',...
    'center33', 'periph33',...
    'center25', 'periph25'};
formant = {'f1' 'f2'};

% initialize empty data structure
for fqs=1:length(freqscale)
    fr = freqscale{fqs};
    for vow=1:length(vowels)
        v = vowels{vow};
        fmtdata.(fr).(v).traces.f1 = [];
        fmtdata.(fr).(v).traces.f2 = []; 
%         for avg=1:length(avgfn)
%             av = avgfn{avg};
%             for ana=1:length(analysis)
%                 an = analysis{ana};
%                 for fmt=1:length(formant)
%                     fm = formant{fmt};
%                     fmtdata.(fr).(v).(av).(an).(fm) = [];
%                 end
%             end
%         end
    end
end

% build up matrix of formant tracks
for i=1:length(dataVals)
    for fmt=1:length(formant)
        fm = formant{fmt};
        y = dataVals(i).(fm);
        traces_hz = fmtdata.hz.(vowels{dataVals(i).word}).traces.(fm);
        fmtdata.hz.(vowels{dataVals(i).word}).traces.(fm) = nancat(traces_hz,y);
        traces_mels = fmtdata.mels.(vowels{dataVals(i).word}).traces.(fm);
        fmtdata.mels.(vowels{dataVals(i).word}).traces.(fm) = nancat(traces_mels,hz2mels(y));
    end
end

% calculate single-trial averages
for fqs=1:length(freqscale)
    fr = freqscale{fqs};
    for vow=1:length(vowels)
        v = vowels{vow};
        for fmt=1:length(formant)
            fm = formant{fmt};
            % strip off first column of NaNs
            if sum(isnan(fmtdata.(fr).(v).traces.(fm)(:,1))) == length(fmtdata.(fr).(v).traces.(fm)(:,1))
                fmtdata.(fr).(v).traces.(fm) = fmtdata.(fr).(v).traces.(fm)(:,2:end);
            end
            for i=1:size(fmtdata.(fr).(v).traces.(fm),2)
                y = fmtdata.(fr).(v).traces.(fm)(:,i);
                fmtdata.(fr).(v).mid50p.rawavg.(fm)(i) = nanmean(midnperc(y,50));
                fmtdata.(fr).(v).first50ms.rawavg.(fm)(i) = nanmean(y(1:round(fs*.05)));
            end
        end
    end
end

% calculate median
for fqs=1:length(freqscale)
    for vow=1:length(vowels)
        for avg=1:length(avgfn)
            for fmt=1:length(formant)
                fr = freqscale{fqs}; v = vowels{vow}; av = avgfn{avg}; fm = formant{fmt};
                fmtdata.(fr).(v).(av).med.(fm) = nanmedian(fmtdata.(fr).(v).(av).rawavg.(fm));
            end
        end
    end
end

% calculate distances, center, and periphery
for fqs=1:length(freqscale)
    for vow=1:length(vowels)
        for avg=1:length(avgfn)
                fr = freqscale{fqs}; v = vowels{vow}; av = avgfn{avg};
                
                f1dist = fmtdata.(fr).(v).(av).rawavg.f1 - fmtdata.(fr).(v).(av).med.f1;
                f2dist = fmtdata.(fr).(v).(av).rawavg.f2 - fmtdata.(fr).(v).(av).med.f2;
                fmtdata.(fr).(v).(av).dist = sqrt(f1dist.^2 + f2dist.^2);
                fmtdata.(fr).(v).(av).meddist = nanmedian(fmtdata.(fr).(v).(av).dist);
                fmtdata.(fr).(v).(av).tertdist = quantile(fmtdata.(fr).(v).(av).dist,2);
                fmtdata.(fr).(v).(av).quardist = quantile(fmtdata.(fr).(v).(av).dist,3);
                
                cent50 = fmtdata.(fr).(v).(av).dist < fmtdata.(fr).(v).(av).meddist;
                peri50 = fmtdata.(fr).(v).(av).dist >= fmtdata.(fr).(v).(av).meddist;
                fmtdata.(fr).(v).(av).center50 = expt.inds.vowels.(v)(cent50);
                fmtdata.(fr).(v).(av).periph50 = expt.inds.vowels.(v)(peri50);
                
                cent33 = fmtdata.(fr).(v).(av).dist < fmtdata.(fr).(v).(av).tertdist(1);
                peri33 = fmtdata.(fr).(v).(av).dist > fmtdata.(fr).(v).(av).tertdist(end);
                fmtdata.(fr).(v).(av).center33 = expt.inds.vowels.(v)(cent33);
                fmtdata.(fr).(v).(av).periph33 = expt.inds.vowels.(v)(peri33);

                cent25 = fmtdata.(fr).(v).(av).dist < fmtdata.(fr).(v).(av).quardist(1);
                peri25 = fmtdata.(fr).(v).(av).dist > fmtdata.(fr).(v).(av).quardist(end);
                fmtdata.(fr).(v).(av).center25 = expt.inds.vowels.(v)(cent25);
                fmtdata.(fr).(v).(av).periph25 = expt.inds.vowels.(v)(peri25);
                
        end
    end
end