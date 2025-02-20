function [e,a,t] = FitEllipse(varargin)
%FITELLIPSE  - computes coordinates of PCA ellipse from 2D xy data
%
%	usage:  [e,a,t] = FitEllipse(x, y, level, exclude, nPoints)
%		or
%			[e,a,t] = FitEllipse(xy, ...)
%
% Given vectors X and Y (or [n x X,Y] array) this procedure fits an ellipse
% using the Principal Components method:  the lengths of the axes are found
% from the eigenvalues of the covariance matrix, with orientiation determined
% by the eigenvectors.
%
% Returns ellipse coordinates E [nPoints x X,Y]
%
% Optional confidence LEVEL controls size of enclosed region (default .95); applied
%	to unitary std. dev. axis lengths
% Optional EXCLUDE trims outliers exceeding this multiple of the std. deviation
%	along each dimension (default 2, [] disables)
% Optional number of points NPOINTS specifies resolution of returned ellipse
%	(default 100)
%
% Optionally returns (normalized) ellipse area A, PC1 angle T (degrees)

% Programmed by Mark Tiede (mkt) in 09/02

%	parse args

if nargin < 1
    eval('help FitEllipse')
    return;
end

level = .95;			% defaults
excl = 2;
nPoints = 177;

x = varargin{1};
if min(size(x)) > 1	% array
    if size(x,2) > size(x,1), x = x'; end
    if size(x,2)>2, error('use FitEllipsoid to plot 3D data'); end
    y = x(:,2);
    x = x(:,1);
    ni = 2;
else					% vectors
    y = varargin{2};
    x = x(:);
    y = y(:);
    ni = 3;
end
if ni<=nargin & ~isempty(varargin{ni}), level = varargin{ni}; end
ni = ni + 1;
if ni<=nargin, excl = varargin{ni}; end
ni = ni + 1;
if ni==nargin & ~isempty(varargin{ni}), nPoints = varargin{ni}; end

%	kill outliers, NaNs

if ~isempty(excl)
    x(find(abs(x-nanmean(x))>nanstd(x)*excl)) = NaN;
    y(find(abs(y-nanmean(y))>nanstd(y)*excl)) = NaN;
    k = any(isnan([x,y]),2);
    x(k) = []; y(k) = [];
end

% 	compute eigenvectors and eigenvalues of means-centered covariance matix

[eVec,eVal] = eig(cov(x,y));

%	compute scaling (applied to one s.d. principal axis lengths)

if level >= 1
    scale = 2;
else
    scale = -norminv((1-level)/2);
end

%	compute ellipse coordinates

t = linspace(0,2*pi,nPoints);
e = (scale * eVec * sqrt(eVal) * [cos(t) ; sin(t)] + repmat(mean([x,y])',1,nPoints))';
% e the points of ellipse
%	compute area, angle

if nargout > 1
    a = pi * prod(scale * sqrt(svd(eVal))); % the area of ellipse
    if eVal(2,2) > eVal(1,1)
        t = acos(eVec(1,2));
    else
        t = asin(eVec(1,2));
    end
    t = t*180/pi;
end

end %EOF
