function varargout = AudapterIO_highFs(action,params,inFrame,varargin)
%
persistent p

toPrompt=0; % set to 1 when necessary during debugging

switch(action)
    case 'init',
        p=params;
        
        if isfield(p, 'downFact')
            Audapter_highFs(3, 'downfact', p.downFact, toPrompt);
        end
  
        Audapter_highFs(3,'srate',p.sr, toPrompt);
        Audapter_highFs(3,'framelen',p.frameLen, toPrompt);
        
        Audapter_highFs(3,'ndelay',p.nDelay, toPrompt);
        Audapter_highFs(3,'nwin',p.nWin, toPrompt);
        Audapter_highFs(3,'nlpc',p.nLPC, toPrompt);
        Audapter_highFs(3,'nfmts',p.nFmts, toPrompt);
        Audapter_highFs(3,'ntracks',p.nTracks, toPrompt);        
        Audapter_highFs(3,'scale',p.dScale, toPrompt);
        Audapter_highFs(3,'preemp',p.preempFact, toPrompt);
        Audapter_highFs(3,'rmsthr',p.rmsThresh, toPrompt);
        Audapter_highFs(3,'rmsratio',p.rmsRatioThresh, toPrompt);
        Audapter_highFs(3,'rmsff',p.rmsForgFact, toPrompt);
        Audapter_highFs(3,'dfmtsff',p.dFmtsForgFact, toPrompt);
        Audapter_highFs(3,'bgainadapt',p.gainAdapt, toPrompt);
        Audapter_highFs(3,'bshift',p.bShift, toPrompt);
        Audapter_highFs(3,'btrack',p.bTrack, toPrompt);
        Audapter_highFs(3,'bdetect',p.bDetect, toPrompt);      
        Audapter_highFs(3,'avglen',p.avgLen, toPrompt);        
        Audapter_highFs(3,'bweight',p.bWeight, toPrompt);    
        
        if (isfield(p,'minVowelLen'))
            Audapter_highFs(3,'minvowellen',p.minVowelLen, toPrompt);
        end
        
        if (isfield(p,'bRatioShift'))
            Audapter_highFs(3,'bratioshift',p.bRatioShift, toPrompt);
        end
        if (isfield(p,'bMelShift'))
            Audapter_highFs(3,'bmelshift',p.bMelShift, toPrompt);
		end
		
%% SC(2009/02/06) RMS Clipping protection
% 		if (isfield(p,'bRMSClip'))
% 			Audapter_highFs(3,'brmsclip',p.bRMSClip, toPrompt);
% 		end
% 		if (isfield(p,'rmsClipThresh'))
% 			Audapter_highFs(3,'rmsclipthresh',p.rmsClipThresh, toPrompt);
% 		end
		
%% SC-Mod(2008/05/15) Cepstral lifting related
        if (isfield(p,'bCepsLift'))
            Audapter_highFs(3,'bcepslift',p.bCepsLift, toPrompt);
        else
            Audapter_highFs(3,'bcepslift',0, toPrompt);
        end
        if (isfield(p,'cepsWinWidth'))
            Audapter_highFs(3,'cepswinwidth',p.cepsWinWidth, toPrompt);
        end        
        
%% Audapter_highFs mode
        if (isfield(p, 'bBypassFmt'))  % Mel
            Audapter_highFs(3, 'bbypassfmt', p.bBypassFmt, toPrompt);
        end

%% SC-Mod(2008/04/04) Perturbatoin field related 
        if (isfield(p,'F2Min'))  % Mel
            Audapter_highFs(3,'f2min',p.F2Min, toPrompt);
        end
        if (isfield(p,'F2Max'))  % Mel
            Audapter_highFs(3,'f2max',p.F2Max, toPrompt);
        end
        if (isfield(p,'F1Min'))
            Audapter_highFs(3,'f1min',p.F1Min, toPrompt);
        end
        if (isfield(p,'F1Max'))
            Audapter_highFs(3,'f1max',p.F1Max, toPrompt);
        end
        if (isfield(p,'LBk'))
            Audapter_highFs(3,'lbk',p.LBk, toPrompt);
        end
        if (isfield(p,'LBb'))
            Audapter_highFs(3,'lbb',p.LBb, toPrompt);
        end
        if (isfield(p,'pertF2'))   % Mel, 257(=256+1) points
            Audapter_highFs(3,'pertf2',p.pertF2, toPrompt);
        end
        if (isfield(p,'pertAmp'))   % Mel, 257 points
            Audapter_highFs(3,'pertamp',p.pertAmp, toPrompt);
        end   
        if (isfield(p,'pertPhi'))   % Mel, 257 points
            Audapter_highFs(3,'pertphi',p.pertPhi, toPrompt);
        end       
        
        if (isfield(p,'fb'))    % 2008/06/18
            Audapter_highFs(3,'fb',p.fb, toPrompt);
        end
        if (isfield(p,'nfb'))    % 2008/06/18
            Audapter_highFs(3,'nfb',p.nfb, toPrompt);
        else
            Audapter_highFs(3, 'nfb', 1, toPrompt);
        end       
        if (isfield(p,'trialLen'))  %SC(2008/06/22)
            Audapter_highFs(3,'triallen',p.trialLen, toPrompt);
        else
            Audapter_highFs(3,'triallen',2.5, toPrompt);
        end
        if (isfield(p,'rampLen'))  %SC(2008/06/22)
            Audapter_highFs(3,'ramplen',p.rampLen, toPrompt);
        else
            Audapter_highFs(3,'ramplen',0.05, toPrompt);
        end
        
        %SC(2008/07/16)
        if (isfield(p,'aFact'))
            Audapter_highFs(3,'afact',p.aFact, toPrompt);
        else
            Audapter_highFs(3,'afact',1, toPrompt);
        end
        if (isfield(p,'bFact'))
            Audapter_highFs(3,'bfact',p.bFact, toPrompt);
        else
            Audapter_highFs(3,'bfact',0.8, toPrompt);
        end
        if (isfield(p,'gFact'))
            Audapter_highFs(3,'gfact',p.gFact, toPrompt);
        else
            Audapter_highFs(3,'gfact',1, toPrompt);
        end
        
        if (isfield(p,'fn1'))
            Audapter_highFs(3,'fn1',p.fn1, toPrompt);
        else
            Audapter_highFs(3,'fn1',500, toPrompt);
        end
        if (isfield(p,'fn2'))
            Audapter_highFs(3,'fn2',p.fn2, toPrompt);
        else
            Audapter_highFs(3,'fn2',1500, toPrompt);
        end
        
        if (isfield(p, 'fb3Gain'));
            Audapter_highFs(3, 'fb3gain', p.fb3Gain, toPrompt);
        end
        
        if (isfield(p, 'fb4GainDB'));
            Audapter_highFs(3, 'fb4gaindb', p.fb4GainDB, toPrompt);
        end
        
        if (isfield(p, 'rmsFF_fb'));
            Audapter_highFs(3, 'rmsff_fb', p.rmsFF_fb, toPrompt);
        end
        
        %SC(2012/03/05) Frequency/pitch shifting
        if (isfield(p, 'bPitchShift'))
            Audapter_highFs(3, 'bpitchshift', p.bPitchShift, toPrompt);
        end
        if (isfield(p, 'pitchShiftRatio'))
            Audapter_highFs(3, 'pitchshiftratio', p.pitchShiftRatio, toPrompt);
        end
        if (isfield(p, 'gain'))
            Audapter_highFs(3, 'gain', p.gain, toPrompt);
        end
        
        if (isfield(p, 'mute'))
            Audapter_highFs(3, 'mute', p.mute, toPrompt);
        end
        
        if (isfield(p, 'pvocFrameLen'))
            Audapter_highFs(3, 'pvocframelen', p.pvocFrameLen, toPrompt);
        end
        if (isfield(p, 'pvocHop'))
            Audapter_highFs(3, 'pvochop', p.pvocHop, toPrompt);
        end
        
        if (isfield(p, 'bDownSampFilt'))
            Audapter_highFs(3, 'bdownsampfilt', p.bDownSampFilt, toPrompt);
        end
        
        if (isfield(p, 'stereoMode'))
            Audapter_highFs(3, 'stereomode', p.stereoMode, toPrompt);
        end
        
        if (isfield(p, 'tsgNTones'))
            Audapter_highFs(3, 'tsgNTones', p.tsgNTones, toPrompt);
        end
        if (isfield(p, 'tsgToneDur'))
            Audapter_highFs(3, 'tsgToneDur', p.tsgToneDur, toPrompt);
        end
        if (isfield(p, 'tsgToneFreq'))
            Audapter_highFs(3, 'tsgToneFreq', p.tsgToneFreq, toPrompt);
        end
        if (isfield(p, 'tsgToneAmp'))
            Audapter_highFs(3, 'tsgToneAmp', p.tsgToneAmp, toPrompt);
        end
        if (isfield(p, 'tsgToneRamp'))
            Audapter_highFs(3, 'tsgToneRamp', p.tsgToneRamp, toPrompt);
        end
        if (isfield(p, 'tsgInt'))
            Audapter_highFs(3, 'tsgInt', p.tsgInt, toPrompt);
        end
        
        if (isfield(p, 'delayFrames'))
            Audapter_highFs(3, 'delayFrames', p.delayFrames, toPrompt);
        end
        
        if (isfield(p, 'wgFreq'))
            Audapter_highFs(3, 'wgFreq', p.wgFreq, toPrompt);
        end
        if (isfield(p, 'wgAmp'))
            Audapter_highFs(3, 'wgAmp', p.wgAmp, toPrompt);
        end
        if (isfield(p, 'wgTime'))
            Audapter_highFs(3, 'wgTime', p.wgTime, toPrompt);
        end
        
%         if isfield(p, 'bTimeDomainShift')
%             Audapter_highFs(3, 'btimedomainshift', p.bTimeDomainShift, toPrompt);
%         else
%             Audapter_highFs(3, 'btimedomainshift', 0, toPrompt);
%         end
%         if isfield(p, 'pitchLowerBoundHz')
%             Audapter_highFs(3, 'pitchlowerboundhz', p.pitchLowerBoundHz, toPrompt);
%         else
%             Audapter_highFs(3, 'pitchlowerboundhz', 0, toPrompt);
%         end
%         if isfield(p, 'pitchUpperBoundHz')
%             Audapter_highFs(3, 'pitchupperboundhz', p.pitchUpperBoundHz, toPrompt);
%         else
%             Audapter_highFs(3, 'pitchupperboundhz', 0, toPrompt);
%         end
%         if isfield(p, 'timeDomainPitchShiftSchedule')
%             if ndims(p.timeDomainPitchShiftSchedule) ~= 2
%                 error('Unexpected number of dimensions in p.timeDomainPitchShiftSchedule: %d',...
%                     ndims(p.timeDomainPitchShiftSchedule));
%             end
%             if length(p.timeDomainPitchShiftSchedule) == 1
%                 Audapter_highFs(3, 'timedomainpitchshiftschedule', ...
%                     p.timeDomainPitchShiftSchedule, toPrompt);
%             elseif size(p.timeDomainPitchShiftSchedule, 2) == 2
%                 % Flatten in row-major order.
%                 psSched = transpose(p.timeDomainPitchShiftSchedule);
%                 Audapter_highFs(3, 'timedomainpitchshiftschedule', psSched(:), toPrompt);
%             elseif size(p.timeDomainPitchShiftSchedule, 1) == 2
%                 Audapter_highFs(3, 'timedomainpitchshiftschedule',...
%                     p.timeDomainPitchShiftSchedule(:), toPrompt);
%             else
%                 error('Unexpected shape in p.timeDomainPitchShiftSchedule');
%             end
%         else
%             Audapter_highFs(3, 'timedomainpitchshiftschedule', 1.0, toPrompt);
%         end
        
        if (isfield(p, 'dataPB'))
            Audapter_highFs(3, 'dataPB', p.dataPB, toPrompt);
        end
        
        return;
%%            
    case 'process',
        Audapter_highFs(5,inFrame);
        return;

    case 'getData',
        nout=nargout;
        [signalMat,dataMat]=Audapter_highFs(4);        
        data=[];

        switch(nout)
            case 1,
%                 data.signalIn       = signalMat(:,1);
%                 data.signalOut      = signalMat(:,2);
% 
%                 data.intervals      = dataMat(:,1);
%                 data.rms            = dataMat(:,2:4);
%                 
%                 offS = 5;
%                 data.fmts           = dataMat(:,offS:offS+p.nTracks-1);
%                 data.rads           = dataMat(:,offS+p.nTracks:offS+2*p.nTracks-1);
%                 data.dfmts          = dataMat(:,offS+2*p.nTracks:offS+2*p.nTracks+1);
%                 data.sfmts          = dataMat(:,offS+2*p.nTracks+2:offS+2*p.nTracks+3);
% 
%                 offS = offS+2*p.nTracks+4;
%                 data.ai             = dataMat(:,offS:offS+p.nLPC);
                
                data.signalIn       = signalMat(:,1);
                data.signalOut      = signalMat(:,2);

                data.intervals      = dataMat(:,1);
                data.rms            = dataMat(:,2:4);
                
                offS = 5;
                data.fmts           = dataMat(:,offS:offS+p.nTracks-1);
                data.rads           = dataMat(:,offS+p.nTracks:offS+2*p.nTracks-1);
                data.dfmts          = dataMat(:,offS+2*p.nTracks:offS+2*p.nTracks+1);
                data.sfmts          = dataMat(:,offS+2*p.nTracks+2:offS+2*p.nTracks+3);

                offS = offS + 2 * p.nTracks + 4;
%                 data.ai             = dataMat(:,offS:offS+p.nLPC);
                
                offS = offS + p.nLPC + 1;
                data.rms_slope      = dataMat(:, offS);
                              
                offS = offS + 1;
                data.ost_stat       = dataMat(:, offS);
                
                offS = offS + 1;
                data.pitchShiftRatio = dataMat(:, offS);
                
                offS = offS + 1;
                if size(dataMat, 2) >= offS
                    data.pitchHz = dataMat(:, offS);
                end
                
                offS = offS + 1;
                if size(dataMat, 2) >= offS
                    data.shiftedPitchHz = dataMat(:, offS);
                end

                data.params         = getAudapterParamSet();

                varargout(1)        = {data};


                return;

            case 2,
                varargout(1)        = {signalMat(:,1)};
                varargout(2)        = {signalMat(:,2)};
                return;

            case 3,
                varargout(1)        = {transdataMat(1:2,2)'};
                varargout(2)        = {transdataMat(1:2,3)'};
                varargout(3)        = {transdataMat(2,1)-transdataMat(1,1)};
                return;

            otherwise,

        end
    case 'reset',
        Audapter_highFs('reset');
        
    case 'ost',
        if nargin == 2
            Audapter_highFs(8, params);
        elseif nargin == 4
            Audapter_highFs(8, params, varargin{1});
        else
            error('%s: Invalid syntax under mode: %s', mfilename, action);
        end
    case 'pcf',
        if nargin == 2
            Audapter_highFs(9, params);
        elseif nargin == 4
            Audapter_highFs(9, params, varargin{1});
        else
            error('%s: Invalid syntax under mode: %s', mfilename, action);
        end
        
        
        
    otherwise,
        
    uiwait(errordlg(['No such action : ' action ],'!! Error !!'));


end
