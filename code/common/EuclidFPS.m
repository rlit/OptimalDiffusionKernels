function [P,D,d,rad] = EuclidFPS(data, N, i0, symLut)

Np = size(data,2);
useLut = exist('symLut','var') && numel(symLut) == Np;

distFun = @(d1,d2) sqrt(sum(bsxfun(@minus,d1,d2).^2,1));

sample = i0; %round(rand*(Np-1)) + 1; % Initialize with a random point.
D      = inf(Np, N);    % Distance maps.
d      = Inf(Np, 1);
P = zeros(N+1,1);
P(1) = sample;
for k = 1:N

    % Compute distance map from sample on the shape.
    curDist =  distFun(data,data(:,P(k)));
    if useLut
        curDist = min(curDist,distFun(data,data(:,symLut(P(k)))));
    end
    
    D(:,k) = curDist;

    if useLut,D(isnan(symLut),k) = NaN;end
    d = min(d, D(:,k));
    if useLut,d(isnan(symLut)) = NaN;end
    [rad, idx] = max(d);
    
    P(k+1) = idx;
end
P = P(1:end-1);

end