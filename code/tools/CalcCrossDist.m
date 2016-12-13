function xDist = CalcCrossDist(shape,idxs,idxs2)

N  = numel(idxs);
Nv = length(shape.X);
D  = inf(Nv, N);    % Distance maps.

fmm = fastmarchmex('init', int32(shape.TRIV-1), double(shape.X(:)), double(shape.Y(:)), double(shape.Z(:)));
for k = 1:N

    % Compute distance map from sample on the shape.
    u = inf(Nv, 1);
    u(idxs(k)) = 0;
    
    D(:,k) = fastmarchmex('march',fmm,double(u));
end
fastmarchmex('deinit', fmm);


if nargin > 2
    xDist   = D(idxs2,:);
else
    xDist   = D(idxs,:);
end
xDist   = min(xDist,xDist');

