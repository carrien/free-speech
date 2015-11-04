function [amplThresh] = get_amplThresh(y_ampl,ampltaxis)
%GET_AMPLTHRESH  Compute amplitude threshold automatically from waveform.

ampltaxis = ampltaxis';
indices2regressi = 442; %every 0.1s  do for 0.04s
indices2regress = indices2regressi;
beginregress = 1;

numregressions = floor(length(y_ampl)/indices2regressi);
cumyhat = [];
cumslopes = [];
newstats{1,numregressions} = [];
thistime = zeros(1,numregressions);

for loop = 1:numregressions
    newstats{1,loop} = regstats(y_ampl(beginregress:indices2regress,1),yampltaxis(beginregress:indices2regress,1));
    beginregress = beginregress + indices2regressi;
    indices2regress = indices2regress + indices2regressi;
    
    thisyhat = newstats{1,loop}.yhat;
    thisslope = (thisyhat(end) - thisyhat(1))/ampltaxis(indices2regressi);
    thistime(1,loop) = ampltaxis(loop*indices2regressi);
    cumyhat = [cumyhat thisyhat'];
    cumslopes = [cumslopes thisslope];
end

firstchangefromzero = find(abs(cumslopes) > 0.5,1,'first') - 1;
timechangefromzero = thistime(1,firstchangefromzero);
indicechangefromzero = find(ampltaxis == timechangefromzero,1);
yvalforamplthresh = y_ampl(indicechangefromzero); %use smoothed amplitude for this
amplThresh = yvalforamplthresh;