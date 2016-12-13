function [trainRes,trainData] = RunTraining(p,alphaVals)
%% flow:
% - 
% - 

%%
startup
if nargin < 1 
    p = GetParams_LSD();
end

if nargin < 2 
    alphaVals = p.alphaVals;
end
alphaVals = unique(alphaVals);

tStartAll = tic;

% crete data for training
tStart = tic;
[tripletIdxs,geoVecs] = GetTrainingData(p);
fprintf('\ntrain data created. took %.3f\n',toc(tStart))

trainRes = {};
descMaxDim = p.descMaxDim;
parfor a = 1:numel(alphaVals)
    tStart = tic;
    alpha = alphaVals(a);
    alphaRes = struct('COV',[],'MMP',[],'alpha',[]);
    alphaRes.alpha  = alpha;
    
    try
        alphaRes.COV = OptimizeMoments(geoVecs,tripletIdxs,alpha,descMaxDim);
    catch me
        fprintf('train COV FAILED on alpha=%.3f - %s\n',alpha, me.message)
    end
    try
%         alphaRes.MMP = MMP_wrapper(    geoVecs,tripletIdxs,alpha,descMaxDim);
    catch me
        fprintf('train MMP FAILED on alpha=%.3f - %s\n',alpha, me.message)
    end    
    
    fprintf('train finished on alpha=%.3f , COVsize = %d , MMPsize = %d , took %.3f\n',alpha,size(alphaRes.COV,1),size(alphaRes.MMP,1),toc(tStart))
    trainRes{a}  = alphaRes; 
end

trainRes = [trainRes{:}];
fprintf('train finished, took %.3f\n',toc(tStartAll))

if nargout > 1
    trainData = struct('tripletIdxs',tripletIdxs,'geoVecs',geoVecs);
end

function [allTripletIdxs, allGeoVecs] = GetTrainingData(p)

% load negetive geometric vectors
negGeoVecs = {};
for c = 1:numel(p.pathDataTrainNeg)
    tmp = GetGeoVecs(p.pathDataTrainNeg{c},p.wildCardTrainNeg{c},p);
    tmp = vertcat(tmp{:});
    negGeoVecs = [negGeoVecs ; num2cell(tmp,2)];%#ok<AGROW>
end

for c = 1:numel(p.pathDataTrain)
    
    fpsData    = FpsFirstShape(p.pathDataTrain{c} ,p.wildCardTrain{c},p.nFpsTrain,1,1);
    
    tripletIdxs = GenerateTripletsIndexes(fpsData.D,p);
    tripletIdxs(:,1) = fpsData.idxs(tripletIdxs(:,1));% fix indices (due to FPS & "find")
    
    geoVecs = GetGeoVecs(p.pathDataTrain{c},p.wildCardTrain{c},p);
    
    curTriplets = GenerateTriplets(geoVecs,tripletIdxs,negGeoVecs); 
    
    allGeoVecs{c} = unique(vertcat(curTriplets{:}),'rows'); %#ok<AGROW>

    [~,allTripletIdxs{c}] = cellfun(@(x)ismember(x,allGeoVecs{c}, 'rows'),curTriplets, 'UniformOutput' , false); %#ok<AGROW>
end

function [geoVecs ] = GetGeoVecs(folder,wildCard,p)
files = dir(fullfile(folder,wildCard));
geoVecs = cell(numel(files),1);
bParams = GetBasisParams(p);
parfor ii = 1:numel(files)
    geoVecs{ii} = FileBasis(fullfile(folder,files(ii).name),bParams);
end

function tripletIdxs = GenerateTripletsIndexes(D,p)

Dsign = zeros(size(D));
Dsign(D <= p.radPosMax & D >p.radPosMax/1000) = +1;
Dsign(D <= p.radNeg2nd & D >p.radNegMin     ) = -1;
Dsign(D >  p.radNeg2nd                      ) = -2;

signCell = num2cell(Dsign,1);

% keep only samples with positives
hasPos   = cellfun(@(s)nnz(s==+1),signCell)  > 0 ...
    &      cellfun(@(s)nnz(s==-1),signCell)  > 0;
signCell = signCell(hasPos);

% perform randsample on every column of Dsign
nSamples = p.nTripletsPerSample;
assert(~mod(nSamples,3),'this is silly, but "nTripletsPerSample" has to be dividable by 3')% make sure it is dividable be 3
posIdxs  = cellfun(@(s){randsample(find(s==+1),nSamples  ,true)} ,signCell );
negIdxs1 = cellfun(@(s){randsample(find(s==-1),nSamples/3,true)} ,signCell );
negIdxs2 = cellfun(@(s){randsample(find(s==-2),nSamples/3     )} ,signCell );
negIdxs3 = cellfun(@(s){                   NaN(nSamples/3,1   )} ,signCell );% these NaN will later be used for negetives not from this class.
negIdxs  = cellfun(@vertcat,negIdxs1,negIdxs2,negIdxs3,'UniformOutput', false);

% create a cell-array similar to posIdxs with the column number in Dsign
hasPosCell = num2cell(find(hasPos));
fpsIdxs    = cellfun(@(i)ones(nSamples,1)*i ,hasPosCell ,'UniformOutput', false);

% Concatenate arrays
tripletIdxs = [vertcat(fpsIdxs{:}) vertcat(posIdxs{:}) vertcat(negIdxs{:})];

function geoVecTriplets = GenerateTriplets(geoVecs,tripletIdxs,negGeoVecs)
% shuffle between shapes of current class
nShapes    = numel(geoVecs);
nPoints    = size(geoVecs{1},1);
assert(all(nPoints == cellfun(@(x)size(x,1),geoVecs)))
nTriplets  = size(tripletIdxs,1);

shuffleFun = @()randsample(nShapes,nTriplets,true)-1;
idxFun = @(i)nPoints * shuffleFun() + tripletIdxs(:,i);
tripletShuffled{3} = idxFun(3);
tripletShuffled{2} = idxFun(2);
tripletShuffled{1} = idxFun(1);

% 
geoVecsCat = vertcat(geoVecs{:});
tf = isnan(tripletShuffled{3});

if isempty(negGeoVecs)
    geoVecTriplets = {...
        geoVecsCat(tripletShuffled{1}(~tf),:),...
        geoVecsCat(tripletShuffled{2}(~tf),:),...
        geoVecsCat(tripletShuffled{3}(~tf),:)};
    return
end

geoVecTriplets = {geoVecsCat(tripletShuffled{1},:),geoVecsCat(tripletShuffled{2},:)};

%
negetives = zeros(size(geoVecTriplets{1}));
negetives(~tf,:) = geoVecsCat(tripletShuffled{3}(~tf),:);
negetives( tf,:) = cell2mat(randsample(negGeoVecs,nnz(tf)));

geoVecTriplets = [geoVecTriplets {negetives}];

