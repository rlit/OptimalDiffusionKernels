function RunPreCalc(p)
%% flow:
% - FPS: sub-sample shapes
% - fix scale
% - LBO
% - build basis
% - 

%%
startup
if nargin < 1 
    p = GetParams_LSD();
end

dsFun = @(f,w)DownSampleDataset(f,w,p.maxShapeVertices);

% run on train data
cellfun(dsFun,            p.pathDataTrain,p.wildCardTrain)
RunOnFolder(@PreCalcLBO,  p.pathDataTrain,p.wildCardTrain,[],p);
bParams = GetBasisParams(p);
RunOnFolder(@PreCalcBasis,p.pathDataTrain,p.wildCardTrain,bParams);

% run on test data
cellfun(dsFun,            p.pathDataTest ,p.wildCardTest)
RunOnFolder(@PreCalcLBO  ,p.pathDataTest ,p.wildCardTest,[],p);
RunOnFolder(@PreCalcBasis,p.pathDataTest ,p.wildCardTest,bParams);

function RunOnFolder(func,folder,wildcard,varargin)
assert(iscell(folder) && iscell(wildcard))
assert( numel(folder) ==  numel(wildcard))

for c = 1:numel(folder)
    files = dir(fullfile(folder{c},wildcard{c}));
    parfor ii = 1:numel(files)
        func(fullfile(folder{c},files(ii).name),varargin{:}); %#ok<PFBNS>
    end
end
function PreCalcBasis(filename,basisParams)
bFile = GetPrecalcFilename(filename,'basis');
if ~(exist(bFile,'file')==2)
    FileBasis(filename,basisParams);
end

function PreCalcLBO(filename,sampleIdxs,p)
if nargin<2,sampleIdxs=[];end
lboFile = GetPrecalcFilename(filename,'lbo');
if p.recomputeLbo || ~(exist(lboFile,'file')==2)
    FileLBO(filename,sampleIdxs);
end
