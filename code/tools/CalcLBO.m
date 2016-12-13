function [evecs,evals,area] = CalcLBO(shape,p)
if nargin < 2 
p = GetParams_LSD();
end

nVert = numel(shape.X);
[W, area] = mshlp_matrix(shape);

% isOk = area>0;
% nOk = nnz(isOk);
% W = W(isOk,isOk);
A = sparse(1:nVert, 1:nVert, area);

% evecs = zeros(nVert,p.nLboVecs);
[evecs,evals] = eigs(W, A, p.nLboVecs, -1e-5, struct('disp', 0));
evals = abs(diag(evals));


[evals, perm] = sort(evals);
evecs = evecs(:,perm);
