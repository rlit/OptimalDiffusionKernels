function symLut = FindSymAlongAxis(shape,symAxis)

if nargin < 2
    symAxis = 1;
end

shapeLocs = [shape.X shape.Y shape.Z]';
centered  = shapeLocs(symAxis,:) - median(shapeLocs(symAxis,:));
idxP = find(centered>=0);
idxN = find(centered<=0);

flipVec = [1 1 1]';
flipVec(symAxis) = -1;
shapeLocsFlipped = bsxfun(@times,shapeLocs,flipVec);


% search on "positive" side
tree = ann('init',  shapeLocsFlipped(:,idxP));
nnN  = ann('search', tree, shapeLocs(:,idxN), 1, 'eps', 0);
ann('deinit', tree);

% search on "negetive" side
tree = ann('init',  shapeLocsFlipped(:,idxN));
nnP  = ann('search', tree, shapeLocs(:,idxP), 1, 'eps', 0);
ann('deinit', tree);

symLut = zeros(size(shape.X));
symLut(idxN) = idxP(nnN);
symLut(idxP) = idxN(nnP);

