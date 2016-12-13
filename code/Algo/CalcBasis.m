function [geoVec, basis] = CalcBasis(evecs,evals,basisParams)

sampleLocs = bsxfun(@minus, evals(:), basisParams.evalSamples) / basisParams.dEval;

switch basisParams.basisType
    case 'cubicHermite_spline'
        basis = cubicHermite_spline(sampleLocs-2);

    case 'cubicB_spline'
        basis = cubicB_spline(sampleLocs);

    case 'wks_kernel'
        basis = wks_kernel(evals,basisParams.evalSamples);

    otherwise
        error('unknown basis type')
end

geoVec     = evecs.^2 * basis;
if basisParams.doNormalize
    geoVec = normalize(geoVec,'l2',2);
end

if basisParams.doSpyBasis
    figure;spy(basis)
end

function weight = cubicHermite_spline(locs)
% code inspired matlab's function interp2\cubic
weight = zeros(size(locs));

flagFun = @(l,h) locs >= l & locs < h;

flag = flagFun(-2,-1); v = locs(flag);
weight(flag) = ((2-v).*v-1).*v;

flag = flagFun(-1,0); v = locs(flag);
weight(flag) = (3*v-5).*v.*v+2;

flag = flagFun(0,1); v = locs(flag);
weight(flag) = ((4-3*v).*v+1).*v;

flag = flagFun(1,2); v = locs(flag);
weight(flag) = (v-1).*v.*v;

weight = weight/12;

function b = cubicB_spline(t)

b = zeros(size(t));

idx4 = find(t >= 0 & t < 1);
idx3 = find(t >= 1 & t < 2);
idx2 = find(t >= 2 & t < 3);
idx1 = find(t >= 3 & t <= 4);

b(idx4) = t(idx4).^3 / 6;
b(idx3) = ( -3*(t(idx3)-1).^3  +3*(t(idx3)-1).^2  +3*(t(idx3)-1)  + 1 ) / 6;
b(idx2) = ( +3*(t(idx2)-2).^3  -6*(t(idx2)-2).^2                  + 4 ) / 6;
b(idx1) = (   -(t(idx1)-3).^3  +3*(t(idx1)-3).^2  -3*(t(idx1)-3)  + 1 ) / 6;

function b = wks_kernel(evals,evalSamples)
n = numel(evalSamples);

lmin  = log(evalSamples(2));
lmax  = log(evalSamples(end));
sigma = 7*(lmax-lmin)/(n+27);
lmin  = lmin+2*sigma;
lmax  = lmax-2*sigma;
E = lmin:(lmax-lmin)/(n-1):lmax;
E(isnan(E)) = (lmax+lmin)/2;

ker = @(evals)( exp(-bsxfun(@minus, E(:), log(evals(:)')).^2 / (2*sigma^2) ) );

b = ker(evals)';
