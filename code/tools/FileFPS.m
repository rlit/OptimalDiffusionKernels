function [fpsData] = FileFPS(fileFullPath,nFpsSamples,symLut,saveAllDistances)

assert(ischar(fileFullPath))
assert(exist(fileFullPath,'file')==2)

if nargin < 3
    symLut = [];
end

[fpsFile filename] = GetPrecalcFilename(fileFullPath,'FPS');

p = GetParams_LSD();
if ~p.recomputeFps && ValidateFileContents(fpsFile,nFpsSamples,symLut,saveAllDistances)
    fprintf('loading FPS for %s...',filename)
    fpsData = load(fpsFile);

else
    shape   = load_shape_sampled(fileFullPath);
%     lboData = FileLBO(fileFullPath);
%     [~,descWks] = GetOldDescs(lboData.evals,lboData.evecs,p.oldDescDim);
    fprintf('calculating FPS for %s...',filename)
%     [fpsData.idxs,D,fpsData.minDist] = FPS_local(descWks,shape,symLut,p);
    [fpsData.idxs,D,fpsData.minDist] = farptsel(shape.TRIV, shape.X, shape.Y, shape.Z, nFpsSamples, 1,symLut);
    fpsData.maxDist = max(D,[],2);
    fpsData.xDist   = D(fpsData.idxs,:);
    fpsData.xDist   = min(fpsData.xDist,fpsData.xDist');

    save(fpsFile,'-struct', 'fpsData', 'idxs','maxDist','minDist','xDist')
    save(fpsFile,'symLut','-append')
    
    if exist('saveAllDistances','var') && isequal(saveAllDistances,1)
        fpsData.D = D;
        save(fpsFile,'D','-append')
    end


end
fprintf('Done.\n')


function isOk = ValidateFileContents(filePath,nFpsSamples,symLut,saveAllDistances)
isOk = true;

if exist(filePath,'file')~=2
    isOk = false;
    return
end

fileVars = who('-file',filePath);
if ...
        ~any(strcmp(fileVars,'idxs')) ||...
        ~any(strcmp(fileVars,'symLut'))
    isOk = false;
    return
end

fileData = load(filePath,'idxs','symLut');

if numel(fileData.idxs) ~= nFpsSamples
    isOk = false;
    return
end

if ~isequalwithequalnans(fileData.symLut , symLut)
    isOk = false;
    return
end

if saveAllDistances && ~any(strcmp(fileVars,'D'))
    isOk = false;
    return
end




function [idxs,D,minDist] = FPS_local(descs,shape,symLut,p)

idxs = EuclidFPS(descs, p.nFpsTrain, 1, symLut);

nVert      = numel(shape.X);
D  = inf(nVert,p.nFpsTrain);    % Distance maps.
d  = Inf(nVert, 1);
fmm = fastmarchmex('init', int32(shape.TRIV-1), double(shape.X(:)), double(shape.Y(:)), double(shape.Z(:)));
for iPoint = 1:p.nFpsTrain
    curIdx = idxs(iPoint);
    u = inf(nVert,1,'double');
    u(curIdx) = 0;
    if ~isempty(symLut)
        u(symLut(curIdx)) = 0;
    end
    D(:,iPoint) = fastmarchmex('march',fmm,u);
    d = min(d, D(:,iPoint));
end

fastmarchmex('deinit', fmm);
% save(fpsFile,'-struct', 'fpsData', 'idxs','maxDist','minDist','xDist')
minDist = d;
