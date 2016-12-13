function bParams = GetBasisParams(p)
if nargin < 1 
    p = GetParams_LSD();
end

allEvals = [];
for c = 1:numel(p.pathDataTrain)
    files = dir(fullfile(p.pathDataTrain{c},p.wildCardTrain{c}));
    for ii = 1:numel(files)
        lboFile = GetPrecalcFilename(fullfile(p.pathDataTrain{c},files(ii).name),'lbo');
        %assert(exist(lboFile,'file')==2)
        if exist(lboFile,'file')~=2 ; FileLBO(fullfile(p.pathDataTrain{c},files(ii).name)); end
        lboData = load(lboFile,'evals');
        allEvals = [allEvals lboData.evals(:)'];%#ok<AGROW>
%         curEvals{ii} = lboData.evals(:)'; %#ok<AGROW>
    end
%     fprintf('%s - %d\n',p.wildCardTrain{c} ,prctile(curEvals{ii},99))
%     allEvals = [allEvals curEvals{:}];%#ok<AGROW>
end

evalRange = [0 prctile(allEvals,99)];
% evalRange(2) = evalRange(2) * .8;
% evalRange = [0 .12];
dEval = diff(evalRange)/(p.nBasisVecs-1);
bParams.evalSamples = evalRange(1):dEval:evalRange(2);
bParams.dEval = dEval;


bParams.basisType   = p.basisType;
bParams.doNormalize = p.normalizeGeoVecs;
bParams.doSpyBasis  = p.plotBasisSpy;
