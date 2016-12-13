function [eer,fpr1,fpr01, dee,dfr1,dfr01, d,fp,fn, fnr1,fnr01] = calculate_rates(dp, dn, wp, wn)

np = length(dp);
nn = length(dn);

if nargin < 3,
    w = ones(length(dp)+length(dn),1);
else
    w = [wp(:); wn(:)];
end

[d0, idx] = sort([dp(:); dn(:)], 'ascend');

d0 = [d0(1)-1; d0(:)];
delta = [d0(2:end)-d0(1:end-1); 0];
d = d0 + delta;

l = [ones(np,1); -ones(nn,1)];
p = [0; (l(idx)>0).*w(idx)];
n = [0; (l(idx)<0).*w(idx)];

p = p/sum(p);
fn = 1-cumsum(p);
n = n/sum(n);
fp = cumsum(n);

[eer,   dee]   = calculate_eer    (fp, fn, d, d0       );
[fpr1,  dfr1]  = calculate_fpatfn (fp, fn, d, d0, 0.01 );
[fpr01, dfr01] = calculate_fpatfn (fp, fn, d, d0, 0.001);
[fnr1,  dfnr1]  = calculate_fnatfp (fp, fn, d, d0, 0.01 );
[fnr01, dfnr01] = calculate_fnatfp (fp, fn, d, d0, 0.001);


% EER
function [eer, dee] = calculate_eer(fp,fn, d,d0)
idx0 = find(fn>fp); 
if isempty(idx0),
    eer = NaN;
    dee = NaN;
else
    idx0 = idx0(end);
    idx1 = idx0 + find(fp(idx0+1:end) > fp(idx0) & fn(idx0+1:end) < fn(idx0));
    if ~isempty(idx1),
        idx1 = idx1(1);
        a    = (fn(idx1)-fn(idx0)) / (fp(idx1)-fp(idx0));
        if a ~= 1,
            eer  = (fn(idx0)-a*fp(idx0)) / (1-a);
            dee  = (eer-fp(idx0))/(fp(idx1)-fp(idx0))*(d0(idx1)-d0(idx0)) + d0(idx0);
        else
            eer  = 0.5*(fp(idx0)+fn(idx0));
            dee  = d(idx0);
        end
    else
        eer  = 0.5*(fp(idx0)+fn(idx0));
        dee  = d(idx0);
    end
end


% FP @ given FN
function [fpr, dpr] = calculate_fpatfn(fp,fn, d,d0, fn_target)
idx0 = find(fn>fn_target); 
if isempty(idx0),
    fpr = NaN;
    dpr = NaN;
else
    idx0 = idx0(end);
    idx1 = idx0 + find(fp(idx0+1:end) > fp(idx0) & fn(idx0+1:end) < fn(idx0));
    if ~isempty(idx1),
        idx1 = idx1(1);
        a    = (fn(idx1)-fn(idx0)) / (fp(idx1)-fp(idx0));
        fpr  = fp(idx0) + (fn_target - fn(idx0))/a;
        dpr  = (fpr-fp(idx0))/(fp(idx1)-fp(idx0))*(d0(idx1)-d0(idx0)) + d0(idx0);
    else
        fpr  = fp(idx0);
        dpr  = d(idx0);
    end
end


% FN @ given FP
function [fnr, dnr] = calculate_fnatfp(fp,fn, d,d0, fp_target)
idx0 = find(fp<fp_target); 
if isempty(idx0),
    fnr = NaN;
    dnr = NaN;
else
    idx0 = idx0(end);
    idx1 = idx0 + find(fp(idx0+1:end) > fp(idx0) & fn(idx0+1:end) < fn(idx0));
    if ~isempty(idx1),
        idx1 = idx1(1);
        a    = (fp(idx1)-fp(idx0)) / (fn(idx1)-fn(idx0));
        fnr  = fn(idx0) + (fp_target - fp(idx0))/a;
        dnr  = (fnr-fn(idx0))/(fn(idx1)-fn(idx0))*(d0(idx1)-d0(idx0)) + d0(idx0);
    else
        fnr  = fn(idx0);
        dnr  = d(idx0);
    end
end
