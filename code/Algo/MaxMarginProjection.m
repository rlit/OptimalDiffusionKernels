%(C) Copyright Alex Bronstein, BBK Technologies ltd, 2009-2010
% Commercial use without prior written consent from bbktech is strictly
% prohibited.
%
% Web: www.bbktech.com
% Email: info@bbktech.com
function [P] = MaxMarginProjection(D, alpha,X,Xp,Xn, X_test,Xp_test,Xn_test, v)


% Dimensions
n = size(X,1);

% Training set size
N = size(X,2);

% Testing set size
if nargin >= 7,
    N_test = size(X_test,2);
    istest = ~isempty(X_test);
    isVerbose = false;
else
    N_test = 0;
    istest = false;
    isVerbose = false;
end

% Internal settings
if nargin < 8, v = 1e-7; end
beta = 2;
tol = 1e-6;

u0 = ones(N,1)/N;
u = u0;

% Initialize iteration
distp = zeros(N,1);
distn = zeros(N,1);
XI    = zeros(n, D);
W     = zeros(D,1);
tr    = 0;
rho   = zeros(N,1);

if istest && isVerbose
    distp_test = zeros(N_test,1);
    distn_test = zeros(N_test,1);
end


% Operate on differences
Xp = Xp - X;
Xn = Xn - X;

if istest,
    Xp_test = Xp_test - X_test;
    Xn_test = Xn_test - X_test;    
end


% Adaboost iterations
str = '';

if isVerbose
    % Evaluate Euclidean distance first
    dp = sum(Xp.^2,1);
    dn = sum(Xn.^2,1);
    [eer,fpr1,fpr01] = calculate_rates(dp, dn, u0, u0);
    mprintf('', 'L2  \t Train \t eer:  %6.4f%% \t fp@1%%:  %6.4f%% \t fp@0.1%%: %6.4f%%\n', eer*100, fpr1*100, fpr01*100 );
    
    if istest
        dp = sum(Xp_test.^2,1);
        dn = sum(Xn_test.^2,1);
        [eer,fpr1,fpr01] = calculate_rates(dp, dn);
        mprintf('', '    \t Test \t eer:  %6.4f%% \t fp@1%%:  %6.4f%% \t fp@0.1%%: %6.4f%%\n', eer*100, fpr1*100, fpr01*100 );
    end
    
    mprintf('', '\n');
end

for d=1:D,
    
    tic;
    
    % Compute outer products
    
    A =   alpha  * bsxfun(@times, Xn, u(:)')*Xn' - ...
       (1-alpha) * bsxfun(@times, Xp, u(:)')*Xp';
    
    % Projection
    [xi,lambda] = eigs(A+A', 1, 'LA', struct('disp',0));
    xi = xi/norm(xi);
    
    % Termination condition
    if lambda < v,
        D = d-1;
        break;
    end
    
    % Project data
    dp = (xi(:)'*Xp).^2;
    dn = (xi(:)'*Xn).^2;
    h = dn - dp;
    
    % Solve for w
    indicator = @(w)( ((h(:)-v).*u(:))'*exp(-w*h(:)) );
    wu = 1; wl = 0;
    while indicator(wu) > -tol, wu = wu*beta; end
    while wu - wl >= tol,
        w = 0.5*(wl + wu);
        if indicator(w) > 0,
            wl = w;
        else
            wu = w;
        end
    end
    
    % Store projection
    XI(:,d) = xi;
    W(d) = w;
    
    % Update u
    u = u(:).*exp(-w*h(:));
    u = u/sum(u);
    
    
    % Update distances
    distp = distp(:) + dp(:) * w;
    distn = distn(:) + dn(:) * w;
    
    
    if isVerbose
        % Calculate function values
        rho = rho + w*h(:);
        tr  = tr + w;
        loss = log(sum(u0.*exp(-rho))) + v*tr;
    
        mprintf(str, '%-4d \t loss: %6.4f \t lambda: %6.6f \t w:       %6.6f \t %s\n', d, loss, lambda, w, format_time(toc) );
        
        [eer,fpr1,fpr01] = calculate_rates(distp, distn, u0, u0);
        mprintf('', '    \t Train \t eer:  %6.4f%% \t fp@1%%:  %6.4f%% \t fp@0.1%%: %6.4f%%\n', eer*100, fpr1*100, fpr01*100 );
        
        if istest,
            dp = (xi(:)'*Xp_test).^2;
            dn = (xi(:)'*Xn_test).^2;
            distp_test = distp_test(:) + dp(:) * w;
            distn_test = distn_test(:) + dn(:) * w;
            [eer,fpr1,fpr01] = calculate_rates(distp_test, distn_test);
            mprintf('', '    \t Test \t eer:  %6.4f%% \t fp@1%%:  %6.4f%% \t fp@0.1%%: %6.4f%%\n', eer*100, fpr1*100, fpr01*100 );
        end
        mprintf('', '\n');
    end
    
end

% Calculate projection matrix
P = bsxfun(@times, XI(:,1:d)', sqrt(W(1:d)));