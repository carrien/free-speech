function [fCen] = calc_vowelCentroid(fmtMeans)
%CALC_VOWELCENTROID  Get vowel centroid given corner vowel formants.

vsX = [fmtMeans.iy(1) fmtMeans.ae(1) fmtMeans.aa(1) fmtMeans.uw(1)];
vsY = [fmtMeans.iy(2) fmtMeans.ae(2) fmtMeans.aa(2) fmtMeans.uw(2)];

[fCen(1),fCen(2)] = centroid(polyshape(vsX,vsY));

end
