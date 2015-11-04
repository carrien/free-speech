function [fmtdata,f0data,ampldata,durdata,trialinds] = calc_fdata(expt,dataVals,condtype)
% CALC_FDATA  Calculate formant, pitch, and ampl data from dataVals object.

if strcmp(expt.name, 'multivowel')
    expt.name = 'mvSIS';
end

if isfield(dataVals,'bExcl')
    exclInds = find([dataVals.bExcl]);
else
    exclInds = [];
end
goodTrials = setdiff(1:length(dataVals),exclInds);

% if isfield(expt,'fs_f0')
%     fs_f0 = expt.fs_f0;
%     fs_fmt = expt.fs_fmt;
%     fs_ampl = expt.fs_ampl;
% else
if isfield(dataVals,'ftrack_taxis')
    diff_f0 = diff(dataVals(goodTrials(1)).pitch_taxis);
    fs_f0 = 1/diff_f0(1);
    diff_fmt = diff(dataVals(goodTrials(1)).ftrack_taxis);
    fs_fmt = 1/diff_fmt(1);
    diff_ampl = diff(dataVals(goodTrials(1)).ampl_taxis);
    fs_ampl = 1/diff_ampl(1);
elseif isfield(dataVals,'vowInt') % from KJR's audioGUI
    diff_f0 = diff(dataVals(goodTrials(1)).f0(:,1));
    fs_f0 = 1/diff_f0(1);
    fs_fmt = 1/diff_f0(1);
    fs_ampl = 1/diff_f0(1);
    for i=1:length(dataVals)
        dataVals(i).vowel = dataVals(i).word;
        dataVals(i).cond = dataVals(i).pert;
    end
else
    warning('No axes found; using default sampling rates.');
    fs_fmt = 333.3333;
    fs_f0 = 11025;
    fs_ampl = 11025;
end

% fs will change based on the scale of each attribute (fmt vs. pitch)

% fmtdata/f0data/ampdata: top level variable
freqscale = {'hz', 'mels'};     % f: frequency scales
switch condtype
    case 'vowel', conds = expt.vowels; %cond = 'word';
    case 'cond', conds = expt.conds;
    case 'word', conds = expt.words;
    otherwise, error('Condition type must be "vowel", "cond", or "word".')
end
avgfn = {'mid50p', 'first50ms', 'mid50p_NaN', 'mid50ms'};  % av: averging functions
formant = {'f1' 'f2'};

% initialize empty data structure
for cnd=1:length(conds)
    c = conds{cnd};
    for fqs=1:length(freqscale)
        fr = freqscale{fqs};
        
        for fmt=1:length(formant)
            fm = formant{fmt};
            fmtdata.(fr).(c).traces.(fm) = [];
        end
        f0data.(fr).(c).traces.f0 = [];
    end
    ampldata.dB.(c).traces.ampl = [];
    durdata.s.(c) = [];
    trialinds.(c) = [];
end

% build up matrix of formant, pitch, and amplitude tracks
for i=goodTrials
    c = conds{dataVals(i).(condtype)}; % condition of this trial
    % formant
    for fmt=1:length(formant)
        fm = formant{fmt};
        y = dataVals(i).(fm);
        if size(y,2) == 2, y = y(:,2); end
        traces_hz = fmtdata.hz.(c).traces.(fm);
        fmtdata.hz.(c).traces.(fm) = nancat(traces_hz,y);
        traces_mels = fmtdata.mels.(c).traces.(fm);
        fmtdata.mels.(c).traces.(fm) = nancat(traces_mels,hz2mels(y));
    end
    % pitch
    y = dataVals(i).f0;
    if size(y,2) == 2, y = y(:,2); end
    traces_hz = f0data.hz.(c).traces.f0;
    f0data.hz.(c).traces.f0 = nancat(traces_hz,y);
    traces_mels = f0data.mels.(c).traces.f0;
    f0data.mels.(c).traces.f0 = nancat(traces_mels,hz2mels(y));
    % ampl
    y = dataVals(i).int;
    if size(y,2) == 2, y = y(:,2); end
    traces_dB = ampldata.dB.(c).traces.ampl;
    ampldata.dB.(c).traces.ampl = nancat(traces_dB,y);
    % duration
    durdata.s.(c)(end+1) = dataVals(i).dur;
    % collect indices
    if isfield(dataVals,'token')
        trialinds.(c)(end+1) = dataVals(i).token;
    else
        trialinds.(c)(end+1) = i;
    end
end

% calculate single-trial averages
for cnd=1:length(conds)
    c = conds{cnd};
    for fqs=1:length(freqscale)
        fr = freqscale{fqs};
        % formant
        for fmt=1:length(formant)
            fm = formant{fmt};
            if ~isempty(fmtdata.(fr).(c).traces.(fm)) && ~sum(~isnan(fmtdata.(fr).(c).traces.(fm)(:,1)))
                fmtdata.(fr).(c).traces.(fm) = fmtdata.(fr).(c).traces.(fm)(:,2:end); % strip off first column of NaNs
            end
            for i=1:size(fmtdata.(fr).(c).traces.(fm),2)
                y = fmtdata.(fr).(c).traces.(fm)(:,i);
                fmtdata.(fr).(c).first50ms.rawavg.(fm)(i) = nanmean(y(1:round(fs_fmt*.05)));
                fmtdata.(fr).(c).mid50p.rawavg.(fm)(i) = nanmean(midnperc(y(~isnan(y)),50));
                noNaNlength = length(y(~isnan(y)));
                if noNaNlength/2 < ceil(fs_fmt*.025), error('Length of non-NaN portion of formant signal is only %d samples. (Trial %d in condition %s)',noNaNlength,goodTrials(i),c); end
                fmtdata.(fr).(c).mid50p_NaN.rawavg.(fm)(i) = nanmean(midnperc(y,50));
                fmtdata.(fr).(c).mid50ms.rawavg.(fm)(i) = nanmean(y(round(noNaNlength/2-fs_fmt*.025):round(noNaNlength/2+fs_fmt*.025)));
            end
        end
        % pitch
        if ~isempty(f0data.(fr).(c).traces.f0) && ~sum(~isnan(f0data.(fr).(c).traces.f0(:,1)))
            f0data.(fr).(c).traces.f0 = f0data.(fr).(c).traces.f0(:,2:end); % strip off first column of NaNs
        end
        for i=1:size(f0data.(fr).(c).traces.f0,2)
            y = f0data.(fr).(c).traces.f0(:,i);
            f0data.(fr).(c).first50ms.rawavg.f0(i) = nanmean(y(1:round(fs_f0*.05)));
            f0data.(fr).(c).mid50p.rawavg.f0(i) = nanmean(midnperc(y(~isnan(y)),50));
            noNaNlength = length(y(~isnan(y)));
            if noNaNlength/2 < ceil(fs_fmt*.025), error('Length of non-NaN portion of pitch signal is only %d samples. (Trial %d in condition %s)',noNaNlength,goodTrials(i),c); end
            f0data.(fr).(c).mid50p_NaN.rawavg.f0(i) = nanmean(midnperc(y,50));
            f0data.(fr).(c).mid50ms.rawavg.f0(i) = nanmean(y(round(noNaNlength/2-fs_fmt*.025):round(noNaNlength/2+fs_fmt*.025)));
        end
    end
    % ampl
    if ~isempty(ampldata.dB.(c).traces.ampl) && ~sum(~isnan(ampldata.dB.(c).traces.ampl(:,1)))
        ampldata.dB.(c).traces.ampl = ampldata.dB.(c).traces.ampl(:,2:end); % strip off first column of NaNs
    end
    for i=1:size(ampldata.dB.(c).traces.ampl,2)
        y = ampldata.dB.(c).traces.ampl(:,i);
        ampldata.dB.(c).first50ms.rawavg.ampl(i) = nanmean(y(1:round(fs_ampl*.05)));
        ampldata.dB.(c).mid50p.rawavg.ampl(i) = nanmean(midnperc(y(~isnan(y)),50));
        noNaNlength = length(y(~isnan(y)));
        if noNaNlength/2 < ceil(fs_fmt*.025), error('Length of non-NaN portion of amplitude signal is only %d samples. (Trial %d in condition %s)',noNaNlength,goodTrials(i),c); end
        ampldata.dB.(c).mid50p_NaN.rawavg.ampl(i) = nanmean(midnperc(y,50));
        ampldata.dB.(c).mid50ms.rawavg.ampl(i) = nanmean(y(round(noNaNlength/2-fs_fmt*.025):round(noNaNlength/2+fs_fmt*.025)));
    end
end

% calculate median
for cnd=1:length(conds)
    c = conds{cnd};
    for avg=1:length(avgfn)
        av = avgfn{avg};
        if isfield(fmtdata.(fr).(c),av)
            for fqs=1:length(freqscale)
                fr = freqscale{fqs};
                % formant
                for fmt=1:length(formant)
                    fm = formant{fmt};
                    fmtdata.(fr).(c).(av).med.(fm) = nanmedian(fmtdata.(fr).(c).(av).rawavg.(fm));
                end
                % pitch
                f0data.(fr).(c).(av).med.f0 = nanmedian(f0data.(fr).(c).(av).rawavg.f0);
            end
            % ampl
            ampldata.dB.(c).(av).med.ampl = nanmedian(ampldata.dB.(c).(av).rawavg.ampl);
        end
    end
end

% calculate distances, center, and periphery
for cnd=1:length(conds)
    c = conds{cnd};
    for avg=1:length(avgfn)
        av = avgfn{avg};
        
        if isfield(fmtdata.(fr).(c),av)
            for fqs=1:length(freqscale)
                fr = freqscale{fqs};
                
                % calculate fdists
                f1dist = fmtdata.(fr).(c).(av).rawavg.f1 - fmtdata.(fr).(c).(av).med.f1;
                f2dist = fmtdata.(fr).(c).(av).rawavg.f2 - fmtdata.(fr).(c).(av).med.f2;
                f0dist_int = f0data.(fr).(c).(av).rawavg.f0 - f0data.(fr).(c).(av).med.f0;
                %f0dist_ext = f0data.(fr).(c).(av).rawavg.f0 - expt.tones(cnd);
                fmtdata.(fr).(c).(av).dist = sqrt(f1dist.^2 + f2dist.^2);
                f0data.(fr).(c).(av).dist = abs(f0dist_int);
                
                % formants
                fmtdata.(fr).(c).(av).meddist = nanmedian(fmtdata.(fr).(c).(av).dist);
                fmtdata.(fr).(c).(av).tertdist = quantile(fmtdata.(fr).(c).(av).dist,2);
                fmtdata.(fr).(c).(av).quardist = quantile(fmtdata.(fr).(c).(av).dist,3);
                
                cent50 = fmtdata.(fr).(c).(av).dist < fmtdata.(fr).(c).(av).meddist;
                peri50 = fmtdata.(fr).(c).(av).dist >= fmtdata.(fr).(c).(av).meddist;
%                fmtdata.(fr).(c).(av).center50 = expt.inds.(sprintf('%ss',condtype)).(c)(cent50);
%                fmtdata.(fr).(c).(av).periph50 = expt.inds.(sprintf('%ss',condtype)).(c)(peri50);
                fmtdata.(fr).(c).(av).center50 = trialinds.(c)(cent50);
                fmtdata.(fr).(c).(av).periph50 = trialinds.(c)(peri50);
                
                cent33 = fmtdata.(fr).(c).(av).dist < fmtdata.(fr).(c).(av).tertdist(1);
                peri33 = fmtdata.(fr).(c).(av).dist > fmtdata.(fr).(c).(av).tertdist(end);
%                fmtdata.(fr).(c).(av).center33 = expt.inds.(sprintf('%ss',condtype)).(c)(cent33);
%                fmtdata.(fr).(c).(av).periph33 = expt.inds.(sprintf('%ss',condtype)).(c)(peri33);
                fmtdata.(fr).(c).(av).center33 = trialinds.(c)(cent33);
                fmtdata.(fr).(c).(av).periph33 = trialinds.(c)(peri33);
                
                cent25 = fmtdata.(fr).(c).(av).dist < fmtdata.(fr).(c).(av).quardist(1);
                peri25 = fmtdata.(fr).(c).(av).dist > fmtdata.(fr).(c).(av).quardist(end);
%                fmtdata.(fr).(c).(av).center25 = expt.inds.(sprintf('%ss',condtype)).(c)(cent25);
%                fmtdata.(fr).(c).(av).periph25 = expt.inds.(sprintf('%ss',condtype)).(c)(peri25);
                fmtdata.(fr).(c).(av).center25 = trialinds.(c)(cent25);
                fmtdata.(fr).(c).(av).periph25 = trialinds.(c)(peri25);
                
                % pitch
                f0data.(fr).(c).(av).meddist = nanmedian(f0data.(fr).(c).(av).dist);
                f0data.(fr).(c).(av).tertdist = quantile(f0data.(fr).(c).(av).dist,2);
                f0data.(fr).(c).(av).quardist = quantile(f0data.(fr).(c).(av).dist,3);
                
                cent50 = f0data.(fr).(c).(av).dist < f0data.(fr).(c).(av).meddist;
                peri50 = f0data.(fr).(c).(av).dist >= f0data.(fr).(c).(av).meddist;
%                f0data.(fr).(c).(av).center50 = expt.inds.(sprintf('%ss',condtype)).(c)(cent50);
%                f0data.(fr).(c).(av).periph50 = expt.inds.(sprintf('%ss',condtype)).(c)(peri50);
                f0data.(fr).(c).(av).center50 = trialinds.(c)(cent50);
                f0data.(fr).(c).(av).periph50 = trialinds.(c)(peri50);

                cent33 = f0data.(fr).(c).(av).dist < f0data.(fr).(c).(av).tertdist(1);
                peri33 = f0data.(fr).(c).(av).dist > f0data.(fr).(c).(av).tertdist(end);
%                f0data.(fr).(c).(av).center33 = expt.inds.(sprintf('%ss',condtype)).(c)(cent33);
%                f0data.(fr).(c).(av).periph33 = expt.inds.(sprintf('%ss',condtype)).(c)(peri33);
                f0data.(fr).(c).(av).center33 = trialinds.(c)(cent33);
                f0data.(fr).(c).(av).periph33 = trialinds.(c)(peri33);
                
                cent25 = f0data.(fr).(c).(av).dist < f0data.(fr).(c).(av).quardist(1);
                peri25 = f0data.(fr).(c).(av).dist > f0data.(fr).(c).(av).quardist(end);
%                f0data.(fr).(c).(av).center25 = expt.inds.(sprintf('%ss',condtype)).(c)(cent25);
%                f0data.(fr).(c).(av).periph25 = expt.inds.(sprintf('%ss',condtype)).(c)(peri25);
                f0data.(fr).(c).(av).center25 = trialinds.(c)(cent25);
                f0data.(fr).(c).(av).periph25 = trialinds.(c)(peri25);
                
            end
            
            ampldist = ampldata.dB.(c).(av).rawavg.ampl - ampldata.dB.(c).(av).med.ampl;
            ampldata.dB.(c).(av).dist = abs(ampldist);
            
            % ampl
            ampldata.dB.(c).(av).meddist = nanmedian(ampldata.dB.(c).(av).dist);
            ampldata.dB.(c).(av).tertdist = quantile(ampldata.dB.(c).(av).dist,2);
            ampldata.dB.(c).(av).quardist = quantile(ampldata.dB.(c).(av).dist,3);
            
            cent50 = ampldata.dB.(c).(av).dist < ampldata.dB.(c).(av).meddist;
            peri50 = ampldata.dB.(c).(av).dist >= ampldata.dB.(c).(av).meddist;
%            ampldata.dB.(c).(av).center50 = expt.inds.(sprintf('%ss',condtype)).(c)(cent50);
%            ampldata.dB.(c).(av).periph50 = expt.inds.(sprintf('%ss',condtype)).(c)(peri50);
            ampldata.dB.(c).(av).center50 = trialinds.(c)(cent50);
            ampldata.dB.(c).(av).periph50 = trialinds.(c)(peri50);
            
            cent33 = ampldata.dB.(c).(av).dist < ampldata.dB.(c).(av).tertdist(1);
            peri33 = ampldata.dB.(c).(av).dist > ampldata.dB.(c).(av).tertdist(end);
%            ampldata.dB.(c).(av).center33 = expt.inds.(sprintf('%ss',condtype)).(c)(cent33);
%            ampldata.dB.(c).(av).periph33 = expt.inds.(sprintf('%ss',condtype)).(c)(peri33);
            ampldata.dB.(c).(av).center33 = trialinds.(c)(cent33);
            ampldata.dB.(c).(av).periph33 = trialinds.(c)(peri33);
            
            cent25 = ampldata.dB.(c).(av).dist < ampldata.dB.(c).(av).quardist(1);
            peri25 = ampldata.dB.(c).(av).dist > ampldata.dB.(c).(av).quardist(end);
%            ampldata.dB.(c).(av).center25 = expt.inds.(sprintf('%ss',condtype)).(c)(cent25);
%            ampldata.dB.(c).(av).periph25 = expt.inds.(sprintf('%ss',condtype)).(c)(peri25);
            ampldata.dB.(c).(av).center25 = trialinds.(c)(cent25);
            ampldata.dB.(c).(av).periph25 = trialinds.(c)(peri25);
        end
        
    end
end