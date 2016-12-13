% farptsel    Farthes point Selection using fast martching
%
% Usage:
% 
%  P = farptsel(TRIV,X,Y,Z, N)
%
% Description: 
%   Selects N points using farthes point selection method and fast marching
%  
% Input:  
% 
%  TRIV    - ntx3 triangulation matrix with 1-based indices (as the one
%            returned by the MATLAB function delaunay).
%  X,Y,Z   - vectors with nv vertex coordinates.
%  N       - number of points to sample
%
% Output:
%
%  P    - the sample points
%
% References:

function [P,D,d,rad] = farptsel(TRIV, X, Y, Z, N, i0, symLut)

f = fastmarchmex('init', int32(TRIV-1), double(X(:)), double(Y(:)), double(Z(:)));

useLut = exist('symLut','var') && numel(symLut) == numel(X);

Nv = length(X);
sample = i0; %round(rand*(Nv-1)) + 1; % Initialize with a random point.
D      = inf(Nv, N);    % Distance maps.
d      = Inf(Nv, 1);
P = zeros(N+1,1);
P(1) = sample;
for k = 1:N

    % Compute distance map from sample on the shape.
    u = inf(Nv, 1);
    u(P(k)) = 0;
    if useLut
        u(symLut(P(k))) = 0;
    end
    
    D(:,k) = fastmarchmex('march',f,double(u));

    if useLut,D(isnan(symLut),k) = NaN;end
    d = min(d, D(:,k));
    if useLut,d(isnan(symLut)) = NaN;end
    [rad, idx] = max(d);
    
    P(k+1) = idx;
end
P = P(1:end-1);

fastmarchmex('deinit', f);
end