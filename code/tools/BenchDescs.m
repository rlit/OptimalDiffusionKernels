function allPerf = BenchDescs(trainData,p,setIdx)
assert(nargin > 0)
tStartAll = tic;

if nargin < 2
    p = GetParams_LSD();
end

if nargin < 3
    setIdx = 1;
end
pathDataTest = p.pathDataTest{setIdx};

testFiles = GetTestFiles(pathDataTest,p.wildCardTest{setIdx},p);

[desc,fpsData] = GetFirstShapeData(trainData,setIdx,testFiles{1},p);

%% compare 1st shape's descriptors to all the rest of the shapes
allPerf = {};
bParams = GetBasisParams(p);
parfor iFile = 2:numel(testFiles)
    tStartFile = tic;
    
    curFile = fullfile(pathDataTest,testFiles{iFile});
    curPerf = struct();
    
    % load LBO
    lbo = load(GetPrecalcFilename(curFile,'lbo'));
    if size(lbo.evecs,1) < size(desc.Hks,2) && isfield(lbo,'idxsKept')
        idxsKept = lbo.idxsKept;
    else
        idxsKept = 1:fpsData.nVert;
    end
    
    % calc old desc
    [descHks2,descWks2] = GetOldDescs(lbo.evals,lbo.evecs,p.oldDescDim);
    curPerf.Hks    = DescPerf(p,desc.Hks,descHks2,fpsData,idxsKept);
    curPerf.Wks    = DescPerf(p,desc.Wks,descWks2,fpsData,idxsKept);
    
    % calc optimal desc
    geoVec = FileBasis(curFile,bParams);
    
    fprintf('testing %s...',testFiles{iFile})
    for ii = 1:numel(trainData)
        curPerf.alpha(ii)  = trainData(ii).alpha;
        descOptCov2        = GetOptDesc(trainData(ii).COV,geoVec);
        descOptMmp2        = GetOptDesc(trainData(ii).MMP,geoVec);
        curPerf.optCov(ii) = DescPerf(p,desc.Opt.Cov{ii},descOptCov2,fpsData,idxsKept);
        curPerf.optMmp(ii) = DescPerf(p,desc.Opt.Mmp{ii},descOptMmp2,fpsData,idxsKept);
    end
    

    
    allPerf{iFile-1} = curPerf;
    fprintf('done, took %.3f\n',toc(tStartFile))
end

allPerf = [allPerf{:}];
fprintf('test finished, took %.3f\n',toc(tStartAll))

function [desc,fpsData] = GetFirstShapeData(trainData,setIdx,firstName,p)
%% calc descriptors & FPS for 1st shape

firstFile = fullfile(p.pathDataTest{setIdx},firstName);
firstShape = load_shape_sampled(firstFile);
symLut = GetDatasetSym(p.pathDataTest{setIdx},p.wildCardTest{setIdx});

fpsData = {};
bParams = GetBasisParams(p);
geoVec = FileBasis(firstFile,bParams);
parfor ii = 1:numel(trainData)
    descOptCov{ii} = GetOptDesc(trainData(ii).COV,geoVec);
    descOptMmp{ii} = GetOptDesc(trainData(ii).MMP,geoVec);
    
    fpsData{ii} = GetTestFps(descOptCov{ii},firstShape,symLut,p,sprintf('COV, alpha=%.3f',trainData(ii).alpha)); %#ok<PFOUS>
%     fpsData{ii} = GetTestFps(descOptMmp{ii},firstShape,symLut,p,sprintf('MMP, alpha=%.3f',trainData(ii).alpha));
end
desc.Opt.Cov = descOptCov;
desc.Opt.Mmp = descOptMmp;

l = load(GetPrecalcFilename(firstFile,'lbo'));
[desc.Hks,desc.Wks] = GetOldDescs(l.evals,l.evecs,p.oldDescDim);
fpsData{end+1}  = GetTestFps(desc.Hks,firstShape,symLut,p,'HKS');
fpsData{end+1}  = GetTestFps(desc.Wks,firstShape,symLut,p,'WKS');

%% unite all FPS data from all descriptors
fpsData = [fpsData{:}];
nVert = [fpsData.nVert]; assert(all(nVert(1) == nVert))
[idxs, m] = unique(vertcat(fpsData.idxs));
gt      = [fpsData.gt];
negLut  = [gt.negLut]; negLut = negLut(m);
posLut  = [gt.posLut]; posLut = posLut(m);
gt      = struct('negLut',{negLut},'posLut',{posLut});
fpsData = struct('nVert',nVert(1),'idxs',idxs,'gt',gt);

fprintf('%d points left after merging all FPS\n\n',numel(idxs))

function perf = DescPerf(p,desc1st,desc2nd,fpsData,idxsKeptIn2nd)
perf = struct('cmc',[],'nVert',[],'dPos',[],'dNeg',[]);
if isempty(desc2nd)
    return
end
gt = fpsData.gt;

% keep FPS & lut indexes that exist in 2nd shape (could be partial shape)
isFpsKept = ismember(fpsData.idxs,idxsKeptIn2nd);

fpsIdxsKept = fpsData.idxs(isFpsKept);
desc1stKept = desc1st(:,fpsIdxsKept);

gt.negLut = FilterLUT(gt.negLut(isFpsKept),idxsKeptIn2nd);
gt.posLut = FilterLUT(gt.posLut(isFpsKept),idxsKeptIn2nd);


%% find k-nearest-neighbors
tree = ann('init',  desc2nd);
nn   = ann('search', tree, desc1stKept, p.kNN, 'eps', 0);
ann('deinit', tree);

%% calc CMC using posLut
nPoints = size(desc1stKept,2);
isCorr  = arrayfun(@(a)ismember(nn(:,a),gt.posLut{a}),1:nPoints,'UniformOutput',0);
isCorr  = [isCorr{:}];

perf.cmc = mean(min(cumsum(isCorr),1),2);
perf.nVert = fpsData.nVert;

%% calc ROC using posLut and negLut
nSmpls = p.nFpsTest;
distFun = @(d1,d2) sqrt(sum(bsxfun(@minus,d1,d2).^2,1));
dPos  = arrayfun(@(i){distFun(desc2nd(:,gt.posLut{i}),desc1stKept(:,i))},1:nSmpls);
dNeg  = arrayfun(@(i){distFun(desc2nd(:,gt.negLut{i}),desc1stKept(:,i))},1:nSmpls);
dNeg2 = {};%arrayfun(@(i){distFun(      gt.negDescs{i} ,desc2(:,i))},1:nSmpls);

perf.dPos = [dPos{:}];
perf.dNeg = [dNeg{:} dNeg2{:}];

function descOpt = GetOptDesc(descBasis,geoVec)
if isempty(descBasis)
    descOpt = [];
    return
end
descOpt = descBasis * geoVec';

function testFiles = GetTestFiles(folder,wildCard,p)
testFiles = dir(fullfile(folder,wildCard));
testFiles = {testFiles.name}';

% remove files that are in the train set
tf = strcmp(folder,p.pathDataTrain);
if p.removeTrainFromTest && any(tf)
    for tf = find(tf);
        tmp = dir(fullfile(p.pathDataTrain{tf},p.wildCardTrain{tf}));
        testFiles = setdiff(testFiles,{tmp.name}');
    end
end

function fpsData = GetTestFps(descs,shape,symLut,p,name)
fpsData = struct('idxs',[],'nVert',[],'D',[],'gt',[]);
if isempty(descs)
    return
end
fprintf('FPSing for %s with %d points...',name,p.nFpsTest)
tStart = tic;
fpsData.idxs = EuclidFPS(descs, p.nFpsTest, 1, symLut);

% shape = load_shape_sampled(fileName);
% [fpsData.idxs,fpsData.D,fpsData.minDist,fpsData.rad] = farptsel(shape.TRIV, shape.X, shape.Y, shape.Z, p.nFpsTest, 1,symLut);
% fpsData.xDist   = fpsData.D(fpsData.idxs,:);
% fpsData.xDist   = min(fpsData.xDist,fpsData.xDist');

fpsData.nVert      = numel(shape.X);
fpsData.D  = inf(fpsData.nVert,p.nFpsTest);    % Distance maps.
fmm = fastmarchmex('init', int32(shape.TRIV-1), double(shape.X(:)), double(shape.Y(:)), double(shape.Z(:)));
for iPoint = 1:p.nFpsTest
    curIdx = fpsData.idxs(iPoint);
    u = inf(fpsData.nVert,1,'double');
    u(curIdx) = 0;
    if ~isempty(symLut)
        u(symLut(curIdx)) = 0;
    end
    fpsData.D(:,iPoint) = fastmarchmex('march',fmm,u);
end

fastmarchmex('deinit', fmm);
fprintf('done, took %.3f\n',toc(tStart))

fpsData.gt = GenerateGroundTruth(fpsData.D,p);
%fpsData.symLut = symLut;

function gt = GenerateGroundTruth(D,p)
% generate ground-truth (with some distance tolerance)
Dcell  = num2cell(D,1);

gt.posLut = cellfun(@(x){find(x<=p.radPosMax)},Dcell);
avgPos = ceil(mean(cellfun(@numel,gt.posLut))); % average number of positive pair

% find negetives from "far" points on the same class
gt.negLut = cellfun(@(x){find(x> p.radNegMin)},Dcell);
gt.negLut = cellfun(@(x){randsample(x,2*avgPos)},gt.negLut); % sample some of the negetive points

return
% add negetives from other classes
[neg.GeoVecs, neg.DescHks, neg.DescWks] = GenerateNegetives(p);
negSamples = cellfun(@(x){randsample(numel(neg.GeoVecs),2*avgPos)},Dcell);
gt.negGeoVecs = cellfun(@(x){vertcat(neg.GeoVecs{x})},negSamples);
gt.negDescWks = cellfun(@(x){horzcat(neg.DescWks{x})},negSamples);
gt.negDescHks = cellfun(@(x){horzcat(neg.DescHks{x})},negSamples);

% function [negGeoVecs, negDescHks, negDescWks] = GenerateNegetives(p)
% % get negetives from other classes
% fprintf('\nLoading negetives for tests\n')
% [negGeoVecs, negDescHks, negDescWks] = deal({});
% for c = 1:numel(p.pathDataTestNeg)
%     [tmpGeo,tmpHks,tmpWks] = GetDatasetDescs(p.pathDataTestNeg{c},p.wildCardTestNeg{c},p);
%     negGeoVecs = [negGeoVecs ; num2cell(vertcat(tmpGeo{:}),2) ];%#ok<AGROW>
%     negDescHks = [negDescHks ; num2cell(horzcat(tmpHks{:}),1)'];%#ok<AGROW>
%     negDescWks = [negDescWks ; num2cell(horzcat(tmpWks{:}),1)'];%#ok<AGROW>
% end
%
% function [geoVecs, descHks, descWks] = GetDatasetDescs(folder,wildCard,p)
% bParams = GetBasisParams(p);
% files   = dir(fullfile(folder,wildCard));
% [geoVecs, descHks, descWks] = deal(cell(numel(files),1));
% parfor ii = 1:numel(files)
%     geoVecs{ii} = FileBasis(fullfile(folder,files(ii).name),bParams);
%     lboData     = FileLBO(  fullfile(folder,files(ii).name));
%     [descHks{ii},descWks{ii}] = GetOldDescs(lboData.evals,lboData.evecs,p.oldDescDim)
% end
% % symLut = GetDatasetSym(folder,wildCard);
% % fpsData = GetTestFps(fullfile(folder,files(1).name,symLut,p);
