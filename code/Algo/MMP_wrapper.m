function basis = MMP_wrapper(data,tripletIdxs,alpha,descDim)

for k = 1:numel(data)
    d     = data{k};
    tIdxs = tripletIdxs{k};
    X{k}  = d(tIdxs{1},:)';%#ok<AGROW>
    Xp{k} = d(tIdxs{2},:)';%#ok<AGROW>
    Xn{k} = d(tIdxs{3},:)';%#ok<AGROW>
end

X  = [(X{:})];
Xp = [(Xp{:})];
Xn = [(Xn{:})];

basis = MaxMarginProjection(descDim, alpha,X,Xp,Xn);