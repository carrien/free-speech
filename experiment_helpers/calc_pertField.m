function [p,h_fig] = calc_pertField(shiftDir,fmtMeans,bMel,bPlot)
%calculate Audapter perturbation field matrix
%inputs:
%    shirtDir: direction of shift ('in' or 'out' or 'control')
%    fmtMeans: struct array with vowels as fields, each with F1 (1) and F2 (2) in Hz
%    bMel: binary variable coding the use of Mels (1) or Hz (0)
%    bPlot: binary variable: create plot (1) or don't (0)
%outputs:
%    p: struct array with the following fields:
%           pertAmp: 257 x 257 matrix of perturbation amplitudes
%           pertPhi: 257 x 257 matrix of perturbation angles
%           f1Min: perturbation field minimum F1 
%           f1Max: perturbation field maximum F1 
%           f2Min: perturbation field minimum F2 
%           f2Max: perturbation field maximum F2 
%
%Ben Parrell JAN 2019
if nargin < 1 || isempty(shiftDir), shiftDir = 'in'; end
if nargin < 2, fmtMeans = []; end
if nargin < 3 || isempty(bMel), bMel = 1;end
if nargin < 4 || isempty(bPlot), bPlot = 1;end

vowels = fieldnames(fmtMeans);
nVow = length(vowels);

%% set defaults if there is more than one value in fmtMeans
% set default formant values if corner vowels not defined in fmtMeans
if nVow ~= 1
    defaultFmtMeans.iy = [342 2322];
    defaultFmtMeans.uw = [378 997];
    defaultFmtMeans.ae = [588 1952];
    defaultFmtMeans.aa = [768 1333];
    defaultVowels = fieldnames(defaultFmtMeans);
    for dv = 1:length(defaultVowels)
        vow = defaultVowels{dv};
        if ~isfield(fmtMeans,vow)
            fmtMeans.(vow) = defaultFmtMeans.(vow);
        end
    end
end

vowels = fieldnames(fmtMeans);

%% initalize pert field
% set size of perturbation field  in Hz
if nVow ~= 1
    F1Min = 200;
    F1Max = 1500;
    F2Min = 500;
    F2Max = 3500;
    if bMel
        F1Min = hz2mels(F1Min);
        F1Max = hz2mels(F1Max);
        F2Min = hz2mels(F2Min);
        F2Max = hz2mels(F2Max);
    end
else
    fieldCen = fmtMeans.(vowels{1});
    fieldRadiusF1 = 100;
    fieldRadiusF2 = 185;
    if bMel
        fieldCen = hz2mels(fieldCen);
        fieldRadiusF1 = 85;
        fieldRadiusF2 = 90;
    end
    F1Min = fieldCen(1)-fieldRadiusF1;
    F1Max = fieldCen(1)+fieldRadiusF1;
    F2Min = fieldCen(2)-fieldRadiusF2;
    F2Max = fieldCen(2)+fieldRadiusF2;
end

% convert formant means to mels
if bMel
    for v = 1:length(vowels)
        vow = vowels{v};
        fmtMeans.(vow) = hz2mels(fmtMeans.(vow));
    end
    
    xlab = 'F1 (mels)';
    ylab = 'F2 (mels)';
else
    xlab = 'F1 (Hz)';
    ylab = 'F2 (Hz)';
end

%initialize perturbation field values with zeros
fieldDim = 257;
pertAmp = zeros(fieldDim,fieldDim);
pertPhi = zeros(fieldDim,fieldDim);

%F1 and F2 values of perturbation field
pertf1 = floor(F1Min:(F1Max-F1Min)/(fieldDim-1):F1Max);
pertf2 = floor(F2Min:(F2Max-F2Min)/(fieldDim-1):F2Max);
[xPertField,yPertField] = meshgrid(pertf1,pertf2);  

%% create pert field
%find pert field location of vowel space center and corner vowels
if nVow ~= 1
    for v = 1:length(vowels)
        vow = vowels{v};
        [~,inds.(vow)(1)] = min(abs(pertf1 - fmtMeans.(vow)(1)));
        [~,inds.(vow)(2)] = min(abs(pertf2 - fmtMeans.(vow)(2)));
    end
    xVS = [inds.iy(1) inds.ae(1) inds.aa(1) inds.uw(1)];
    yVS = [inds.iy(2) inds.ae(2) inds.aa(2) inds.uw(2)];

    %find center of vowel area
    [fCen(1),fCen(2)] = centroid(polyshape({pertf1(xVS)}, {pertf2(yVS)}));
else
    fCen = fmtMeans.(vowels{1});
end
[~,iFCen(1)] = min(abs(pertf1 - fCen(1)));
[~,iFCen(2)] = min(abs(pertf2 - fCen(2)));

pertScaleFact = 1;
for iF1 = 1:fieldDim
    for iF2 = 1:fieldDim
        dF1 = pertf1(iFCen(1))-pertf1(iF1);
        dF2 = pertf2(iFCen(2))-pertf2(iF2);
        switch shiftDir
            case 'in'
                pertAmp(iF2,iF1) = sqrt(dF2.^2+dF1.^2).*pertScaleFact;
                pertPhi(iF2,iF1) = atan(dF2/abs(dF1));
                if dF1<0
                        pertPhi(iF2,iF1) = pi - pertPhi(iF2,iF1);
                end
%                 pertPhi(pertPhi<0) = pertPhi(pertPhi<0)+2*pi;
%                 pertAmp(abs(pertAmp)<1) = 0;
            case 'out'
                pertAmp(iF2,iF1) = sqrt(dF2.^2+dF1.^2).*pertScaleFact;
                pertPhi(iF2,iF1) = pi+atan(dF2/abs(dF1));
                if dF1<0
                        pertPhi(iF2,iF1) = pi - pertPhi(iF2,iF1);            
                end
%                 pertPhi(test<0) = pertPhi(test<0)+2*pi;
%                 pertAmp(abs(pertAmp)<1) = 0;
            case 'control'
                pertAmp(iF2,iF1) = 0;
                pertPhi(iF2,iF1) = pi+atan(dF2/abs(dF1));
                if dF1<0
                        pertPhi(iF2,iF1) = pi - pertPhi(iF2,iF1);            
                end

            otherwise
                error("shiftDir must be 'in or 'out' or 'control'")
        end
        
    end
end

% remove NaNs which can result from atan(0/0)
pertPhi(isnan(pertPhi)) = 0;

%% plot pert field
if bPlot
    h_fig = figure;        
    
    if nVow ~= 1
        fillcolor = [.945 .945 .945];
        fill(pertf1(xVS), pertf2(yVS),fillcolor)
    end
    arrowcolor = 'r';
    
    hold on
    plotInd = 1:10:257;
    pertAmp2Plot = pertAmp;
    pertAmp2Plot(pertAmp>400) = 0; %for display only
    [u,v] = pol2cart(pertPhi,pertAmp2Plot);
    quiver(xPertField(plotInd,plotInd),yPertField(plotInd,plotInd),u(plotInd,plotInd),v(plotInd,plotInd),'Color',arrowcolor)
    plot(pertf1(iFCen(1)),pertf2(iFCen(2)),'+k')
    for v = 1 :length(vowels)
        vow = vowels{v};
        textLoc = fmtMeans.(vow);
        text(textLoc(1),textLoc(2),vow)
    end
    
    xlabel(xlab);
    ylabel(ylab);

    drawnow;
end

%% asign values to output variable (p)
p.bShift2D = 1;     % flag for 2D experiments
p.pertAmp2D = pertAmp';     % convert to Audapter naming scheme w/ 2D
p.pertPhi2D = pertPhi';     % convert to Audapter naming scheme w/ 2D
p.pertf1 = pertf1;
p.pertf2 = pertf2;
p.F1Min = F1Min;
p.F1Max = F1Max;
p.F2Min = F2Min;
p.F2Max = F2Max;
p.fCen = fCen;

end
