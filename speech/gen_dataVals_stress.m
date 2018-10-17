function [] = gen_dataVals_stress(dataPath,trialdir)
%GEN_DATAVALS_VOT  Scrape subject trial files for data and save.
%   GEN_DATAVALS_VOT(DATAPATH,TRIALDIR) scrapes the files from a subject's
%   DATAPATH/TRIALDIR directory and collects formant data into the single
%   file DATAVALS.mat.
%
%CN 5/2018
% Revised for stress by SB 6/2018
%GEN_DATAVALS_STRESS
%
%   for multi-syllable words, disregarding VOT.
%   script assumes the following regarding user events:
%   If there is only one user event, it's marking the end of the word.
%   If there are two or more events, they're marking the on- and offset of
%   all syllables.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end

max_events = 4; % three events for VOT study: word onset, voice onset, word offset

% set output file
%savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
%bSave = savecheck(savefile);
%if ~bSave, return; end

% load expt files
load(fullfile(dataPath,'expt.mat'));
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
sortedTrials = get_sortedTrials(trialPath);
shortTracks_syll1 = [];
shortTracks_syll2 = [];
dataVals_syll1 = struct([]);
dataVals_syll2 = struct([]);

% extract tracks from each trial
for i = 1:length(sortedTrials)
    trialnum = sortedTrials(i);
    filename = sprintf('%d.mat',trialnum);
    load(fullfile(trialPath,filename));
    
    word = expt.allWords(trialnum);
    if isfield(expt,'allColors')
        color = expt.allColors(trialnum);
    else
        color = [];
    end
    
    if strcmp(expt.listStress(trialnum),'trochee');
        dataVals_syll1(trialnum).stress=1;
        dataVals_syll2(trialnum).stress=0;
    else if strcmp(expt.listStress(trialnum),'iamb');
            dataVals_syll1(trialnum).stress=0;
            dataVals_syll2(trialnum).stress=1;
        end
    end
    
    
    
    
    
    % skip bad trials
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params) && ~trialparams.event_params.is_good_trial
        dataVals_syll1(trialnum).bExcl = 1 %~trialparams.event_params.is_good_trial;
        dataVals_syll2(trialnum).bExcl = 1 %~trialparams.event_params.is_good_trial;
        dataVals_syll1(i).word = word;
        dataVals_syll1(i).vowel = expt.allVowels(trialnum);
        dataVals_syll1(i).color = color;
        dataVals_syll1(i).cond = expt.allConds(trialnum);
        dataVals_syll1(i).token = trialnum;
        
        dataVals_syll2(i).word = word;
        dataVals_syll2(i).vowel = expt.allVowels(trialnum);
        dataVals_syll2(i).color = color;
        dataVals_syll2(i).cond = expt.allConds(trialnum);
        dataVals_syll2(i).token = trialnum;
    else
        dataVals_syll1(trialnum).bExcl = 0;
        dataVals_syll2(trialnum).bExcl = 0;
    
        
        
        
        if exist('trialparams','var') ...
                && isfield(trialparams,'event_params') ...
                && ~isempty(trialparams.event_params) 
            user_event_times = sort(trialparams.event_params.user_event_times);
        else
            user_event_times = [];
        end
        
        n_events = length(user_event_times);
        
        if n_events > max_events
            warning('%d events found in trial %d (expected %d or fewer)',n_events,trialnum,max_events);
            fprintf('ignoring event %d\n',max_events+1:n_events)
        end
        % find first syllable vowel onset
        % changed onset_time to onset_time1
        if n_events > 1
            % find time of first user-created event
            onset_time1 = user_event_times(1);
            onset1IndAmp = get_index_at_time(sigmat.ampl_taxis,onset_time1);
            % find also the second onset
            onset_time2 = user_event_times(3);
            onset2IndAmp = get_index_at_time(sigmat.ampl_taxis,onset_time2);
        else
            % use amplitude threshold to find suprathreshold indices
            if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                % use trial-specific amplitude threshold
                amplInds = find(sigmat.ampl > trialparams.sigproc_params.ampl_thresh4voicing);
            else % use wave_viewer_params default amplitude threshold
                amplInds = find(sigmat.ampl > sigproc_params.ampl_thresh4voicing);
            end
            % set onset to first suprathreshold index
            if amplInds
                onset1IndAmp = amplInds(1) + 1;
            else
                onset1IndAmp = 1; % set trial BAD here? reason: no onset found?
            end
            onset_time1 = sigmat.ampl_taxis(onset1IndAmp);
        end
        
        
        if n_events == 4
            offsetEventInd1 = 2;
            offsetEventInd2 = 4;
        else
            if n_events == 1
                offsetEventInd2 =1;
            else
                if n_events
                    error('Missing event for trial %d (%d found). Require either 0, 1 or 4 events',trialnum,n_events);
                end
            end
        end
        
        
        
        
        % find offsets
        if n_events > 1
            %    if n_events >= offsetEventInd1 && user_event_times(offsetEventInd1) ~= user_event_times(offsetEventInd-1)
            % find time of user-created offset event
            offset_time1 = user_event_times(offsetEventInd1);
            offset1IndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time1);
            % if you have index 1, you definitely also have index 2.
            offset_time2 = user_event_times(offsetEventInd2);
            offset2IndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time2);
            
        else
            % find first sub-threshold amplitude value after onset
            if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                % use trial-specific amplitude threshold
                amplInds = find(sigmat.ampl(onset1IndAmp:end) < trialparams.sigproc_params.ampl_thresh4voicing);
            else % use wave_viewer_params default amplitude threshold
                amplInds = find(sigmat.ampl(onset1IndAmp:end) < sigproc_params.ampl_thresh4voicing);
            end
            % set offset to first subthreshold index after word/voice onset
            if amplInds
                offset1IndAmp = amplInds(1) - 1 + onset1IndAmp; % correct indexing: subtract the 1 we added earlier because we're adding the onset bits
            else
                error('Unable to find syll 1 offset for trial %d (%d found).',trialnum,n_events) % if you can't find the offset the whole trial is botched
                %            offset1IndAmp = length(sigmat.ampl); % use last index if no offset found
            end
            offset_time1 = sigmat.ampl_taxis(offset1IndAmp); % or -1?
            %        offset_time2 = sigmat.ampl_taxis(offset2IndAmp);
            % and now you can get onset2
            %         if onset_time2
            %             error('Missing event for trial %d (%s found). if no offset marked then onset should not be marked.',trialnum,n_event_str)
            %         end
            % use amplitude indices we already found
            % amplInds = all indices where amplitude is above threshold
            if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                % use trial-specific amplitude threshold
                amplInds = find(sigmat.ampl(offset1IndAmp:end) > trialparams.sigproc_params.ampl_thresh4voicing);
            else % use wave_viewer_params default amplitude threshold
                amplInds = find(sigmat.ampl(offset1IndAmp:end) > sigproc_params.ampl_thresh4voicing);
            end
            
            
            if amplInds
                onset2IndAmp = amplInds(1) - 1 + offset1IndAmp; % correct indexing
            else
                onset2IndAmp = length(sigmat.ampl); % use last index if no offset found
            end
            
            onset_time2 = sigmat.ampl_taxis(onset2IndAmp);
            
            % now do this again to get offset
            if exist('trialparams','var') && ~isempty(trialparams.sigproc_params)
                % use trial-specific amplitude threshold
                amplInds = find(sigmat.ampl(onset2IndAmp:end) < trialparams.sigproc_params.ampl_thresh4voicing);
            else % use wave_viewer_params default amplitude threshold
                amplInds = find(sigmat.ampl(onset2IndAmp:end) < sigproc_params.ampl_thresh4voicing);
            end
            
            
            if amplInds
                offset2IndAmp = amplInds(1) - 1 + onset2IndAmp; % correct indexing
            else
                offset2IndAmp = length(sigmat.ampl); % use last index if no offset found
            end
            
            offset_time2 = sigmat.ampl_taxis(offset2IndAmp);
            
            
        end
        
        
        
        
        
        
        
        % find vowel onset
        %    if % write some other conditional %%%%%%%any(strncmp(color,{'p' 't' 'k' 'b' 'd' 'g'},1))
        %
        % find time of second user-created event
        
        
        
        % I think we don't actually need this block. If you realize you do, check back in the original VOT script because this is totally botched now.
        % % % %  % find vowel offset
        % % % %         if n_events > 1 && user_event_times(1) ~= user_event_times(2)
        % % % %             offset_time1 = user_event_times(2);
        % % % % %            vowelOnsetIndAmp = get_index_at_time(sigmat.ampl_taxis,offset_time1);
        % % % % %            offsetEventInd = 3;
        % % % %         else
        % % % %             % check if bad trial
        % % % % %             if ~trialparams.event_params.is_good_trial
        % % % % %                 % if bad trial, don't throw error; use word onset as vowel onset
        % % % % %                 offset_time1 = onset_time;
        % % % % %                 vowelOnsetIndAmp = onsetIndAmp;
        % % % % %  %               offsetEventInd = 2;
        % % % % %             else
        % % % %                 % if good trial, error
        % % % %                 if n_events
        % % % %                     n_event_str = 'only 1 event';
        % % % %                 else
        % % % %                     n_event_str = 'no events';
        % % % %                 end
        % % % % %                error('Voice onset event not set for trial %d (%s found).',trialnum,n_event_str)
        % % % % %            end
        % % % %         end
        % % % %     else
        % % % %         % use word onset as vowel onset
        % % % % %        offset_time1 = onset_time;
        % % % % %        vowelOnsetIndAmp = onsetIndAmp;
        % % % % %        offsetEventInd = 2;
        % % % %     end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        % find onset/offset indices for each track
        onset1Indf0 = get_index_at_time(sigmat.pitch_taxis,onset_time1);
        onset2Indf0 = get_index_at_time(sigmat.pitch_taxis,onset_time2);
        offset1Indf0 = get_index_at_time(sigmat.pitch_taxis,offset_time1);
        offset2Indf0 = get_index_at_time(sigmat.pitch_taxis,offset_time2);
        onset1Indfx = get_index_at_time(sigmat.ftrack_taxis,onset_time1);
        onset2Indfx = get_index_at_time(sigmat.ftrack_taxis,onset_time2);
        offset1Indfx = get_index_at_time(sigmat.ftrack_taxis,offset_time1);
        offset2Indfx = get_index_at_time(sigmat.ftrack_taxis,offset_time2);
        
        % convert to dataVals struct
        
        dataVals_syll1(i).f0 = sigmat.pitch(onset1Indf0:offset1Indf0)';
        dataVals_syll2(i).f0 = sigmat.pitch(onset1Indf0:offset2Indf0)';
        dataVals_syll1(i).f1 = sigmat.ftrack(1,onset1Indfx:offset1Indfx)'; % 1 = first formant
        dataVals_syll2(i).f1 = sigmat.ftrack(1,onset2Indfx:offset2Indfx)';
        dataVals_syll1(i).f2 = sigmat.ftrack(2,onset1Indfx:offset1Indfx)';
        dataVals_syll2(i).f2 = sigmat.ftrack(2,onset2Indfx:offset2Indfx)';
        dataVals_syll1(i).int = sigmat.ampl(onset1IndAmp:offset1IndAmp)';
        dataVals_syll2(i).int = sigmat.ampl(onset2IndAmp:offset2IndAmp)';
        dataVals_syll1(i).pitch_taxis = sigmat.pitch_taxis(onset1Indf0:offset1Indf0)';
        dataVals_syll2(i).pitch_taxis = sigmat.pitch_taxis(onset2Indf0:offset2Indf0)';
        dataVals_syll1(i).ftrack_taxis = sigmat.ftrack_taxis(onset1Indfx:offset1Indfx)';
        dataVals_syll2(i).ftrack_taxis = sigmat.ftrack_taxis(onset2Indfx:offset2Indfx)';
        dataVals_syll1(i).ampl_taxis = sigmat.ampl_taxis(onset1IndAmp:offset1IndAmp)';
        dataVals_syll2(i).ampl_taxis = sigmat.ampl_taxis(onset2IndAmp:offset2IndAmp)';
        dataVals_syll1(i).dur = offset_time1 - onset_time1;
        dataVals_syll2(i).dur = offset_time2 - onset_time2;
        
        dataVals_syll1(i).word = word;
        dataVals_syll1(i).vowel = expt.allVowels(trialnum);
        dataVals_syll1(i).color = color;
        dataVals_syll1(i).cond = expt.allConds(trialnum);
        dataVals_syll1(i).token = trialnum;
        
        dataVals_syll2(i).word = word;
        dataVals_syll2(i).vowel = expt.allVowels(trialnum);
        dataVals_syll2(i).color = color;
        dataVals_syll2(i).cond = expt.allConds(trialnum);
        dataVals_syll2(i).token = trialnum;
        
%         
%         if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
%             dataVals_syll1(i).bExcl = ~trialparams.event_params.is_good_trial;
%         else
%             dataVals_syll1(i).bExcl = 0;
%         end
%         
        
        %     if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        %         dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
        %     else
        %         dataVals(i).bExcl = 0;
        %     end
        
        
%         if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
%             dataVals_syll2(i).bExcl = ~trialparams.event_params.is_good_trial;
%         else
%             dataVals_syll2(i).bExcl = 0;
%         end
        
        
        
        % warn about short tracks
        
        if ~dataVals_syll1(i).bExcl && dataVals_syll1(i).stress ==1 && sum(~isnan(dataVals_syll1(i).f0)) < 20
            shortTracks_syll1 = [shortTracks_syll1 dataVals_syll1(i).token];
            warning('Short pitch track: trial %d',dataVals_syll1(i).token);
        end
        if ~dataVals_syll1(i).bExcl && dataVals_syll1(i).stress ==1 && sum(~isnan(dataVals_syll1(i).f1)) < 20
            shortTracks_syll1 = [shortTracks_syll1 dataVals_syll1(i).token];
            warning('Short formant track: trial %d',dataVals_syll1(i).token);
        end
        
        if ~dataVals_syll1(i).bExcl && dataVals_syll1(i).stress ==0 && sum(~isnan(dataVals_syll1(i).f0)) < 6
            shortTracks_syll1 = [shortTracks_syll1 dataVals_syll1(i).token];
            warning('Short pitch track: trial %d',dataVals_syll1(i).token);
        end
        if ~dataVals_syll1(i).bExcl && dataVals_syll1(i).stress ==0 && sum(~isnan(dataVals_syll1(i).f1)) < 6
            shortTracks_syll1 = [shortTracks_syll1 dataVals_syll1(i).token];
            warning('Short formant track: trial %d',dataVals_syll1(i).token);
        end
        
        
        
        if ~isempty(shortTracks_syll1)
            shortTracks_syll1 = unique(shortTracks_syll1);
            warning('Short track list for syllable 1: %s',num2str(shortTracks_syll1));
        end
        
        
        
        
        
        if ~dataVals_syll2(i).bExcl &&dataVals_syll2(i).stress ==1 && sum(~isnan(dataVals_syll2(i).f0)) < 20
            shortTracks_syll2 = [shortTracks_syll2 dataVals_syll2(i).token];
            warning('Short pitch track: trial %d',dataVals_syll2(i).token);
        end
        if ~dataVals_syll2(i).bExcl &&  dataVals_syll2(i).stress ==1 &&sum(~isnan(dataVals_syll2(i).f1)) < 20
            shortTracks_syll2 = [shortTracks_syll2 dataVals_syll2(i).token];
            warning('Short formant track: trial %d',dataVals_syll2(i).token);
        end
        
        if ~dataVals_syll2(i).bExcl &&dataVals_syll2(i).stress ==0 && sum(~isnan(dataVals_syll2(i).f0)) < 6
            shortTracks_syll2 = [shortTracks_syll2 dataVals_syll2(i).token];
            warning('Short pitch track: trial %d',dataVals_syll2(i).token);
        end
        if ~dataVals_syll2(i).bExcl &&  dataVals_syll2(i).stress ==0 &&sum(~isnan(dataVals_syll2(i).f1)) < 6
            shortTracks_syll2 = [shortTracks_syll2 dataVals_syll2(i).token];
            warning('Short formant track: trial %d',dataVals_syll2(i).token);
        end
        
        
        
        if ~isempty(shortTracks_syll2)
            shortTracks_syll2 = unique(shortTracks_syll2);
            warning('Short track list for syllable 2: %s',num2str(shortTracks_syll2));
        end
    end
end


save('dataVals_syll1.mat','dataVals_syll1');
%fprintf('%d trials saved in %s.\n',length(sortedTrials),savefile)

save('dataVals_syll2.mat','dataVals_syll2');
%fprintf('%d trials saved in %s.\n',length(sortedTrials),savefile)


end
