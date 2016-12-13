function p = GetParams_LSD()
%% paths
p.pathCode      = fileparts(mfilename('fullpath'));
p.pathData      = fullfile(fileparts(p.pathCode),'data');

% p.data  = GetDataParams(p);
% p.train = GetTrainParams(p);
% p.test  = GetTestParams(p);


%--------------------------------------------------------------------------
% % TRAIN
p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'victoria*.mat';
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'david*.mat';
% p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
% p.wildCardTrain{end+1} = 'michael*.mat';
% % % p.pathDataTrain{end+1}  = fullfile(p.pathData ,'tosca');
% % % p.wildCardTrain{end+1}  = 'centaur*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTrain{end+1}  = 'dog*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTrain{end+1}  = 'cat*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTrain{end+1}  = 'horse*.mat';

% p.pathDataTrain{end+1} = fullfile(p.pathData ,'shrec10');
% p.wildCardTrain{end+1} = '*.mat';

% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh00*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh05*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh02*.mat';


p.pathDataTrainNeg = {};
p.wildCardTrainNeg = {};
% p.pathDataTrainNeg{end+1} = fullfile(p.pathData ,'stanford');
% p.wildCardTrainNeg{end+1} = '*.mat';
% p.pathDataTrainNeg{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTrainNeg{end+1}  = 'horse*.mat';
% % p.pathDataTrainNeg{end+1}  = fullfile(p.pathData ,'tosca');
% % p.wildCardTrainNeg{end+1}  = 'centaur*.mat';
% p.pathDataTrainNeg{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTrainNeg{end+1}  = 'dog*.mat';
% p.pathDataTrainNeg{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTrainNeg{end+1}  = 'cat*.mat';

%--------------------------------------------------------------------------
% % TEST
p.pathDataTest  = {};
p.wildCardTest  = {};
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTest{end+1} = 'david*.mat';
p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
p.wildCardTest{end+1}  = 'michael*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTest{end+1}  = 'victoria*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTest{end+1}  = 'horse*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTest{end+1}  = 'dog*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTest{end+1}  = 'cat*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
% p.wildCardTest{end+1}  = 'centaur*.mat';

% p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTest{end+1}  = 'mesh0*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTest{end+1}  = 'mesh00*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTest{end+1}  = 'mesh01*.mat';
p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
p.wildCardTest{end+1}  = 'mesh03*.mat';

%%
% % % % % p.pathDataTestNeg  = {};
% % % % % p.wildCardTestNeg  = {};
% % % % % p.pathDataTestNeg{end+1}  = fullfile(p.pathData ,'tosca');
% % % % % p.wildCardTestNeg{end+1}  = 'centaur*.mat';
% % % % % % p.pathDataTestNeg{end+1}  = fullfile(p.pathData ,'tosca');
% % % % % % p.wildCardTestNeg{end+1}  = 'david*.mat';
% % % % % % p.pathDataTestNeg{end+1}  = fullfile(p.pathData ,'tosca');
% % % % % % p.wildCardTestNeg{end+1}  = 'victoria*.mat';
% % % % % % p.pathDataTestNeg{end+1}  = fullfile(p.pathData ,'tosca');
% % % % % % p.wildCardTestNeg{end+1}  = 'michael*.mat';


%% 
p.maxShapeVertices  = 10e3; % otherwise it will be downsampled

p.nLboVecs   = 300;
p.nBasisVecs = 150;
p.nFpsTrain  = 1000;
p.nFpsTest   = 1000;

% p.basisType = 'cubicHermite_spline';
p.basisType = 'cubicB_spline';
% p.basisType = 'wks_kernel';

% p.testName = 'default_test_name';

p.nTripletsPerSample = 75;

p.recomputeFps   = false;
p.recomputeLbo   = false;
p.recomputeBasis = false;

p.normalizeGeoVecs = true;
p.plotBasisSpy     = false;

p.removeTrainFromTest = 1; % wheateher to ensure that Train & Test are disjoint

% radii for self-positives and self-negetives
p.radPosMax = 2;
p.radNegMin = 4;
p.radNeg2nd = 16;


p.alphaVals  = 2.^(-3:.25:-1.5);
p.descMaxDim = 64;%ceil(p.nBasisVecs / 2);
p.oldDescDim = p.descMaxDim;

p.maxPrctileToPlot = 50;
p.kNN = ceil(p.nFpsTest / 10); % <-used for descriptor analisys (i.e. CMC , etc.)

