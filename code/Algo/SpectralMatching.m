function [out1,out2] = SpectralMatching(desc1,desc2,xDist1,xDistFun2,kNN)
n1 = size(desc1,2);
nPairs = kNN*n1;

tree = ann('init',  desc2);
[nnIdx descDist]  = ann('search', tree, desc1, kNN, 'eps', 0);
ann('deinit', tree);

% % % filter bad matched (descriptor-wise)
% descTh = prctile(descDist(:),[25 50 75]) * [-1 1 1]';
% % nnz(descDist > descTh)/numel(descDist)
% % hist(descDist(:),50)

nnIdx    = double(nnIdx(:));
[nnUnq, ~, i2] = unique(nnIdx);
i1 = kron((1:n1)',ones(kNN,1));

fprintf('calculating cross distance on %d points...',numel(nnUnq))
t = tic;
xDist2 = xDistFun2(nnUnq);
fprintf('took %.3f\n',toc(t))
% hist([xDist1(:) ; xDist2(:)],50)

%% create affinity matrix
fprintf('creating affinity matrix...')
t = tic;

pct = 1;
sigma = 4;%prctile([xDist1(:) ; xDist2(:)],pct);
diffTh = 20;
affMat = CalcAffinityMatrix(i1,i2,xDist1,xDist2,sigma,diffTh);

% % % add diag
% pct = 1;
% sigma = prctile(descDist(:),pct);
% diagDesc = exp(-(descDist(:)/sigma).^2);
% diagDesc(diagDesc < 1e-7) = 0;
% affMat = affMat + 300* diag(diagDesc);


% figure
% spy(affMat)

fprintf('matrix %.2f%% full. took %.3f\n',100*nnz(affMat)/numel(affMat),toc(t))

% %% calc prime eigen vector
[eVec,~] = eigs(affMat,1);
[eVec,perm] = sort(eVec,'ascend');
eVec = eVec/eVec(1);
% figure
% plot(abs(eVec),'displayname',['diag ' num2str(pct)])

%% get matches
GetTriu = @(m)m(triu(true(size(m)),1));

isUsed1 = false(n1,1);
isUsed2 = false(numel(nnUnq),1);
out1= [];
out2= [];
confi = [];
descD = [];
distor = struct([]);%[];
for i = 1:nPairs
    
    curPair = perm(i);
    cur1 = i1(curPair);
    cur2 = i2(curPair);
    if isUsed1(cur1) || isUsed2(cur2)
        continue
    end
    
    isUsed1(cur1) = 1;
    isUsed2(cur2) = 1;
    out1(end+1,1) = cur1; %#ok<AGROW>
    out2(end+1,1) = cur2; %#ok<AGROW>
    
    confi(end+1,1) = eVec(i);%#ok<AGROW>
    descD(end+1,1) = descDist(curPair)/median(descDist(:));%#ok<AGROW>
    
    if i > 1 
        xDiff = GetTriu(abs(xDist1(out1,out1) - xDist2(out2,out2)));
        d.mean = mean(xDiff);
        d.min = min(xDiff);
        d.med = median(xDiff);
        d.max = max(xDiff);
        if isempty(distor)
            distor = d;
        else
            distor(end+1,1) = d;%#ok<AGROW>
        end
    end
    
end

% revert to original inexes
out2 = nnUnq(out2);


% [i1(perm) i2(perm)]
%%
% figure
% xDiff = (abs(xDist1(out1,out1) - xDist2(out2,out2)));
% imagesc(xDiff);axis equal tight

% figure;
% plotyy(1:99,[distor.max],1:100,confi)

% figure
% plot(confi,'ro','displayname',['' num2str(pct)])
% figure
% plot(eVec,'displayname',['' num2str(pct)])

% PlotMax = @(x,c,s)plot(x,c,'displayname',s);
% figure; hold on
% PlotMax([distor.max],'r','max')
% % PlotMax([distor.min],'g','min')
% % PlotMax([distor.med],'b','med')
% % PlotMax([distor.mean],'k','mean')
% PlotMax(confi,'ro-','confidence')
% % PlotMax(descD,'bo-','descDist')
% legend show

function affMat = CalcAffinityMatrix(i1,i2,xDist1,xDist2,sigma,diffTh)
nPairs = numel(i1);
assert(nPairs==numel(i2));
affMat = zeros(nPairs,nPairs);
for r = 1:nPairs-1
    for c = r:nPairs
        if i1(c) == i1(r) || i2(c) == i2(r)
            continue
        end
        d1 = xDist1(i1(c),i1(r));
        d2 = xDist2(i2(c),i2(r));
        diff = abs(d1 - d2);
        aff = exp(-(diff/sigma).^2);
        if aff < 1e-7 || diff > diffTh || diffTh > d1  || diffTh > d2
            continue
        end
        affMat(r,c) = aff;
         
    end
end
affMat = affMat + affMat';

%%
% figure(32457);clf
% x = 0:.5:20;
% plot(x,exp(-(x/7).^2))
% 
