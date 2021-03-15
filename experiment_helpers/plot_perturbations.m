function h_fig = plot_perturbations(fmtMeans,shifts,vowel2shift,bMel)
%Plots formant perturbations for studies using audapter.
%
%Inputs:    
%   fmtMeans: means of formants measured in a baseline phase
%   shifts: a vector of shifts that will be imposed. can be taken directly
%       from expt.shifts.mels or expt.shifts.hz (see bMel)
%   vowel2shift: a string with the name of the vowel that will be shifted
%       in the experiment. this is used to center the shift vectors in
%       F1/F2 space
%   bMel: 1 x 2 vector representing whether inputs are in Hz (0) or 
%       mels (1). Default behavior is to assume formant means are in Hz 
%       and perturbations are in mels. All plotting is done in mels.


if nargin < 3
    error("Not enough inputs. Expects 1) formants means, 2) vector of shifts, 3) vowel to be shifted")
end
if nargin < 4
    bMel = [0 1];
end

%get vowels to plot
vowels = fieldnames(fmtMeans);
nVow = length(vowels);

%get plot colors
plotColors = varycolor(nVow);

h_fig = figure;
hold on

%plot the vowels
for v = 1:nVow
    vow = vowels{v};
    if ~bMel(1)
        fmtMeans.(vow)(1) = hz2mel(fmtMeans.(vow)(1));
        fmtMeans.(vow)(2) = hz2mel(fmtMeans.(vow)(2));
    end
    plot(fmtMeans.(vow)(1),fmtMeans.(vow)(2),'o','MarkerSize',10,...
        'MarkerFaceColor',plotColors(v,:),'MarkerEdgeColor',plotColors(v,:));
end

%plot the perturbations
center = fmtMeans.(vowel2shift);
nPerts = length(shifts);
for p = 1:nPerts
    if ~bMel(2)
        shift = hz2mel(shifts{p});
    else
        shift = shifts{p};
    end
    if any(abs(shift)>0)
        quiver(center(1),center(2),shift(1),shift(2),0,...
            'Color','k','LineWidth',3);
    end
end
xlabel('F1 (mels)')
ylabel('F2 (mels)')
axis equal
makeFig4Screen

