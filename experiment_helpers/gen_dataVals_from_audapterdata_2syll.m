function [] = gen_dataVals_from_audapterdata_2syll(dataPath,bSaveCheck,savefilename,nsylls,buffer,bPlotCutoffs)
%GEN_DATAVALS_FROM_AUDAPTERDATA create dataVals from audapter
%   GEN_DATAVALS_FROM_AUDAPTERDATA(DATAPATH,TRIALDIR,BSAVECHECK) use
%   data.mat audpater fmts and sfmts to create dataVals


if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(bSaveCheck), bSaveCheck = 1; end
if nargin < 3 || isempty(savefilename), savefilename = 'dataVals'; end
if nargin < 4 || isempty(nsylls), nsylls = 2; end
if nargin < 5 || isempty(buffer), buffer = 'signalIn'; end
if nargin < 6 || isempty(bPlotCutoffs), bPlotCutoffs = 1; end

savefn = [savefilename '_' buffer '.mat'];

%if nsylls > 1
%    suffix1 = ['_syll1'];
%    savefn = [savefilename suffix1 '_' buffer '.mat'];
%end

savefile = fullfile(dataPath,savefn);
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if ~bSave, return; end


load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,'data.mat'));
dataVals = struct([]);
shortTracks = [];
skipme = zeros(1,length(data));
% set onset and offset thresholds
onsetThresh = .04;
offsetThresh = .04;


for trialnum = 1:length(data)
    
    % if trial exists, load in to get events
    tr2load = [num2str(trialnum) '.mat'];
    file2load = fullfile(dataPath,'trials',tr2load);
    if exist(file2load) == 2
        load(file2load,'trialparams');
        if isfield(trialparams, 'event_params') && isfield(trialparams.event_params,'is_good_trial') && trialparams.event_params.is_good_trial == 0
            sprintf('bad trial is %d',trialnum)
            continue
        else
            if isfield(trialparams,'event_params') && isfield(trialparams.event_params,'user_event_times') && length(trialparams.event_params.user_event_times) == 4
                if strcmpi(expt.name,'uhdapter') || strcmpi(expt.name,'uhdapter_down') % Different expts have different expected user events. Is there a better way to do this?
                    for n = 1:nsylls
                        onsetTimes(n) = trialparams.event_params.user_event_times((2*n)-1);
                        offsetTimes(n) = trialparams.event_params.user_event_times(2*n);
                        onsetInds(n) = onsetTimes(n)*data(trialnum).params.sr/data(trialnum).params.frameLen;
                        offsetInds(n) = offsetTimes(n)*data(trialnum).params.sr/data(trialnum).params.frameLen;
                    end
                    t_intervals = (data(trialnum).intervals)/1000;  % puts time intervals in indices that are relative to data
                    
                    % use time to get fmt indices
                    %for n = 1:nsylls
                    
                else
                    continue
                end
            else
                % if there are no events
                load(file2load,'sigmat');
                for n = 1:nsylls
                    if n==1
                        startamp = 1;
                    else
                        startamp = offsetIndAmp(n-1);
                    end
                    
                    % use amplitude threshold to find suprathreshold indices
                    if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                        % use trial-specific amplitude threshold
                        amplInds = find(sigmat.ampl(startamp:length(sigmat.ampl)) > trialparams.sigproc_params.ampl_thresh4voicing);
                    else % use wave_viewer_params default amplitude threshold
                        amplInds = find(sigmat.ampl(startamp:length(sigmat.ampl)) > sigproc_params.ampl_thresh4voicing);
                    end
                    % set onset to first suprathreshold index
                    if amplInds
                        onsetIndAmp(n) = amplInds(1) + 1;
                    else
                        onsetIndAmp(n) = 1; % set trial BAD here? reason: no onset found?
                    end
                    
                    if exist('offsetIndAmp','var')
                        onsetIndAmp(n) = onsetIndAmp(n)-1+offsetIndAmp(n-1); % if on any syllable n, n > 1, add on the sample of the most recent offset
                    end
                    
                    onsetTimes(n) = sigmat.ampl_taxis(onsetIndAmp(n));
                    onsetInds(n) = onsetTimes(n)*data(trialnum).params.sr/data(trialnum).params.frameLen;
                    
                    clear amplInds
                    
                    % get offset time
                    
                    if n == nsylls && isfield(trialparams,'event_params') && isfield(trialparams.event_params,'user_event_times') && length(trialparams.event_params.user_event_times) == 1
                        offsetTimes(n) = trialparams.event_params.user_event_times;
                        offsetInds(n) = offsetTimes(n)*data(trialnum).params.sr/data(trialnum).params.frameLen;
                    else
                        
                        if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                            % use trial-specific amplitude threshold
                            amplInds = find(sigmat.ampl(onsetIndAmp(n):end) < trialparams.sigproc_params.ampl_thresh4voicing);
                        else % use wave_viewer_params default amplitude threshold
                            amplInds = find(sigmat.ampl(onsetIndAmp(n):end) < sigproc_params.ampl_thresh4voicing);
                        end
                        
                        
                        % set offset to first subthreshold index after word/voice onset
                        if amplInds
                            offsetIndAmp(n) = amplInds(1) - 1 + onsetIndAmp(n); % correct indexing: subtract the 1 we added earlier because we're adding the onset bits
                        elseif length(sigmat.ampl(onsetIndAmp(n):end) > 20) && bPlotCutoffs
                            offsetIndAmp(n) = length(sigmat.ampl); % use with caution
                            warning('End of syllable likely cut off, trial %d',trialnum)
                            figure; plot(sigmat.ampl_taxis,sigmat.ampl)
                            what2do = input('Use final sample as offset? y/n', 's')
                            if strcmpi(what2do,'n')
                                skipme(trialnum)=1;
                                continue
                            end
                        else
                            error('Unable to find syll 1 offset for trial %d (syllable %d).',trialnum,n) % if you can't find the offset the whole trial is botched
                            %            offset1IndAmp = length(sigmat.ampl); % use last index if no offset found
                        end
                        offsetTimes(n) = sigmat.ampl_taxis(offsetIndAmp(n)); % or -1?
                        offsetInds(n) = offsetTimes(n)*data(trialnum).params.sr/data(trialnum).params.frameLen;
                    end
                    clear amplInds
                    
                end
                t_intervals = (data(trialnum).intervals)/1000;
                
            end
        end
    else
        
        % in cases where there are no event markers, we might need to
        % borrow some code from regular gen_dataVals_from_waveviewer
        
        % find onset using threshold for rms
        rms = data(trialnum).rms(:,1);
        onsetInd = min(find(rms > onsetThresh));  % finds onsetInd: first index in rms that is above onsetThresh
        offsetInd = min(find(rms(onsetInd+1:end) < offsetThresh)) + onsetInd;  % finds offsetInd: first index after onsetInd+1 that is below offsetThresh
        
        % find onset and offset times
        t_intervals = (data(trialnum).intervals)/1000;  % puts time intervals in indices that are relative to data
        onset_time = t_intervals(onsetInd);
        offset_time = t_intervals(offsetInd);
        
    end
    
    for n = 1:nsylls
        if ~skipme(trialnum)%exist('onsetInds','var')
            
            if nsylls > 1
                onsetInd = onsetInds(n);
                offsetInd = offsetInds(n);
                onset_time = onsetTimes(n);
                offset_time = offsetTimes(n);
                %                suffix = ['_syll' num2str(n)];
                %                savefn = [savefilename suffix '_' buffer '.mat'];
                %                savefile = fullfile(dataPath,savefn);
            end
            
            syll = ['syll' num2str(n)];
            
            %     dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';                     % f0 track from onset to offset
            if strcmpi(buffer,'signalIn')
                ftype = 'fmts';
                dataVals(trialnum).(syll).f3 = data(trialnum).(ftype)(onsetInd:offsetInd,3);
            else
                ftype = 'sfmts';
            end
            dataVals(trialnum).(syll).f1 = data(trialnum).(ftype)(onsetInd:offsetInd,1);                  % f1 track from onset to offset
            dataVals(trialnum).(syll).f2 = data(trialnum).(ftype)(onsetInd:offsetInd,2);                  % f2 track from onset to offset
            dataVals(trialnum).(syll).int = data(trialnum).rms(onsetInd:offsetInd,1);                   % intensity (rms amplitude) track from onset to offset
            %     dataVals(trialnum).(syll).pitch_taxis = sigmat.pitch_taxis(onsetInd:offsetInd)';      % pitch time axis
            dataVals(trialnum).(syll).ftrack_taxis = t_intervals(onsetInd:offsetInd);    % formant time axis
            %     dataVals(trialnum).(syll).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';      % amplitude time axis
            dataVals(trialnum).(syll).dur = offset_time - onset_time;                                 % duration
            dataVals(trialnum).(syll).word = expt.allWords(trialnum);                                 % numerical index to word list (e.g. 2)
            dataVals(trialnum).(syll).vowel = expt.allVowels(trialnum);                               % numerical index to vowel list (e.g. 1)
            if isfield(expt,'allColors')
                dataVals(trialnum).(syll).color = expt.allColors(trialnum);                           % numerical index to color list (e.g. 1)
            end
            if isfield(expt,'allStress')
                if expt.allStress(trialnum)==n
                    dataVals(trialnum).(syll).stress = 1;
                else
                    dataVals(trialnum).(syll).stress=0;
                end
            end
            dataVals(trialnum).(syll).cond = expt.allConds(trialnum);                                 % numerical index to condition list (e.g. 1)
            dataVals(trialnum).(syll).token = trialnum;                                               % trial number (e.g. 22)
            dataVals(trialnum).(syll).bExcl = 0;                                                      % binary variable: 1 = exclude trial, 0 = don't exclude trial
            
            % warn about short tracks
            if sum(~isnan(dataVals(trialnum).(syll).f1)) < 20
                shortTracks = [shortTracks dataVals(trialnum).(syll).token];
                warning('Short formant track: trial %d',dataVals(trialnum).(syll).token);
            end
        end
    end
    clear onsetTimes
    clear offsetTimes
    clear onsetInds
    clear offsetInds
    clear onsetIndAmp
    clear offsetIndAmp
end
save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(data),savefile)
end



