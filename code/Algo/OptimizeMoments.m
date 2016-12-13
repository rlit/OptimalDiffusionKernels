function [descBasis] = OptimizeMoments(geoVecs,tripletIdxs,alpha,descMaxDim)
% TODO - detect dimensions with zero variance & ignore them (& also pass dimensions indices back)
unqGeoVecs = unique(vertcat(geoVecs{:}),'rows'); 
C     = cov(unqGeoVecs);
Csqrt = sqrtm(C);

% create pairs
for k = 1:numel(geoVecs)
    gv = geoVecs{k};
    tIdxs = tripletIdxs{k};
    diffPos{k} = gv(tIdxs{2},:) - gv(tIdxs{1},:); %#ok<AGROW>
    diffNeg{k} = gv(tIdxs{3},:) - gv(tIdxs{1},:); %#ok<AGROW>
end
diffPos = vertcat(diffPos{:});
diffNeg = vertcat(diffNeg{:});

% Cpos = cov(diffPos);
% Cneg = cov(diffNeg);
Cpos = diffPos' * diffPos;
Cneg = diffNeg' * diffNeg;

A = Csqrt \( (1-alpha)*Cpos - alpha*Cneg ) / Csqrt;

% 
[U,L] = eig(A);
l = diag(L);
[l,idx] = sort(l,'ascend');
U = U(:,idx);

% set numer of dimensions & create a basis
lastNegVal = find(l<0,1,'last'); 
assert(~isempty(lastNegVal),'no negetive evals')
% if isempty(lastNegVal)
%     lastNegVal = 1;
%     warning('\t !!! no negetive evals for alpha=%d !!!\n',alpha) %#ok<WNTAG>
% end
nDims = min(lastNegVal,descMaxDim);

U = U(:,1:nDims)*abs(diag(l(1:nDims)));
descBasis = U' / Csqrt;

