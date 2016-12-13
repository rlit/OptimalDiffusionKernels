function PlotAllSimMaps(p,trainRes,saveDir,idx)


files = dir(fullfile(p.pathDataTest{1},p.wildCardTest{1}));
files = {files.name}';
fileIdx = 14;
filePath = fullfile(p.pathDataTest{1},files{fileIdx});

if nargin < 4
%     idx = 3988;%michael wrist
%     idx = 3716;%michael elbow
%     idx = 4353;%michael index finger
%     idx = 2055;%michael head top
%     idx = 8031;%michael foot thumb
%     idx = 709;%michael nipple
%     idx = 534;%michael belly

%     shape = load_shape_sampled(filePath);
%     [~,idx] = min(shape.X)
%     [~,idx] = min(shape.Y)
%     [~,idx] = max(shape.X)
%     [~,idx] = max(shape.Y)
%      [~,idx] = max(shape.Z)
end

refData = PlotShapeSimMaps(filePath,p,trainRes,saveDir,idx);
%%

files = dir(fullfile(p.pathDataTest{2},p.wildCardTest{2}));
files = {files.name}';
fileIdx = 9;
filePath = fullfile(p.pathDataTest{2},files{fileIdx});

PlotShapeSimMaps(filePath,p,trainRes,saveDir,refData);

%%

files = dir(fullfile(p.pathDataTest{1},p.wildCardTest{1}));
files = {files.name}';
fileIdx = 18;
filePath = fullfile(p.pathDataTest{1},files{fileIdx});

PlotShapeSimMaps(filePath,p,trainRes,saveDir,refData);


function [refDataOut] = PlotShapeSimMaps(filePath,p,trainRes,saveDir,refDataIn)
[~, fileName] = fileparts(filePath);
saveDir = fullfile(p.pathData,'perf_plots',saveDir);
MakeDir(saveDir)
%%
shape = load_shape_sampled(filePath);
geoVec = FileBasis(filePath,GetBasisParams(p));
for ii = 1:numel(trainRes)
    descOptCov = GetOptDesc(trainRes(ii).COV,geoVec);
    curStr = 'OPT';%sprintf('OPT cov%.3f',trainRes(ii).alpha);
    if isstruct(refDataIn)
        PlotOneSimMap(saveDir,shape,fileName,descOptCov,curStr,refDataIn.Cov(ii));
    else
        refDataOut.Cov(ii).maxVal = PlotOneSimMap(saveDir,shape,fileName,descOptCov,curStr,refDataIn);
        refDataOut.Cov(ii).desc   = descOptCov(:,refDataIn);
    end
    

end

%%
% l = load(GetPrecalcFilename(filePath,'lbo'));
l = FileLBO(filePath);
[descHks,descWks] = GetOldDescs(l.evals,l.evecs,p.oldDescDim);
if isstruct(refDataIn)
    PlotOneSimMap(saveDir,shape,fileName,descHks,'HKS',refDataIn.Hks);
    PlotOneSimMap(saveDir,shape,fileName,descWks,'WKS',refDataIn.Wks);
else
    refDataOut.Hks.maxVal = PlotOneSimMap(saveDir,shape,fileName,descHks,'HKS',refDataIn);
    refDataOut.Wks.maxVal = PlotOneSimMap(saveDir,shape,fileName,descWks,'WKS',refDataIn);
    refDataOut.Hks.desc   = descHks(:,refDataIn);
    refDataOut.Wks.desc   = descWks(:,refDataIn);
end

function descOpt = GetOptDesc(descBasis,geoVec)
if isempty(descBasis)
    descOpt = [];
    return
end
descOpt = descBasis * geoVec';

function maxVal = PlotOneSimMap(saveDir,shape,shapeName,desc,descName,refData)
p = GetParams_LSD();
if isscalar(refData) && ~isstruct(refData)
    idx = refData;
    descAtIdx = desc(:,idx);

else
    idx = [];
    descAtIdx = refData.desc;
    maxVal = refData.maxVal;
end
%%

dif = bsxfun(@minus,desc,descAtIdx);
descDist   = sqrt(sum(dif.^2,1))';

fPlot = figure('color','w','renderer','zbuffer','units','pixels','position',[100 100 600 600]);
PlotShape(shape,descDist)
% view(0,0)
view(3)
shading interp 

if ~isempty(idx)
    hold on
    plot3(...
        shape.X(idx),...
        shape.Y(idx),...
        shape.Z(idx),...
        'ok','MarkerFaceColor','w',...
        'MarkerSize',7)
    
    maxVal = prctile(descDist, p.maxPrctileToPlot);
end
set(fPlot,'name',descName,'numberTitle','off')


set(gca,'clim',prctile(descDist,[0 p.maxPrctileToPlot]),'position',[0 0 1 1])
% set(gca,'clim',[0 maxVal],'position',[0 0 1 1]);
% set(gca,'clim',[min(descDist) maxVal],'position',[0 0 1 1]);

colormap([jet(255); [1 0 0]*0.35])

h=colorbar ;
set(get(h,'YLabel'),'String',[descName ' L_2 distance'])

%% save
nameStr = fullfile(saveDir,[shapeName '_' descName]);
saveas(fPlot,[nameStr,'.fig'])
%saveas(fPlot,[nameStr,'.png'])
colorbar('off')

%% render
light
camlight head
lighting phong

fRender = myaa(4);
saveas(fRender,[nameStr,'.png'])
close(fRender)

%% make tight
pngData  = imread([nameStr,'.png']);
notWhite = any(pngData<254,3);
pngData  = pngData(any(notWhite,2),any(notWhite,1),:);
notWhite = notWhite(any(notWhite,2),any(notWhite,1),:);
imwrite(pngData,[nameStr,'.png'],'png','Alpha',double(notWhite));

close(fPlot)

