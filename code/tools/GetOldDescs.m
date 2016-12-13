function [descHks,descWks] = GetOldDescs(evals,evecs,descSize)
n = descSize;

%%
tmin    = 8;
tmax    = 14;
tvals   = 2.^linspace(tmin,tmax,n);
expVal  = exp(-bsxfun(@times, evals(:)          , tvals(:)'));
descHks =      bsxfun(@times,(evecs.^2) * expVal, tvals(:)')';
descHks = normalize(descHks, 'l2', 1);

%%
lmin  = log(1.428e-4);
lmax  = log(0.115);
sigma = 7*(lmax-lmin)/(n+27);
lmin  = lmin+2*sigma;
lmax  = lmax-2*sigma;
E = lmin:(lmax-lmin)/(n-1):lmax;
E(isnan(E)) = (lmax+lmin)/2;
ker = @(evals)( exp(-bsxfun(@minus, E(:), log(evals(:)')).^2 / (2*sigma^2) ) );
descWks = ker(evals) * evecs.^2';
descWks = normalize(descWks, 'l2', 1);

