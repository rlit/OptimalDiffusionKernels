
folder = '2013-06-11_08-55-22_FullBench';
load(['Z:\Documents\MATLAB\OptimalDiffusionKernels\data\perf_plots\' folder '\TOSCA_on_TOSCA\trainRes.mat']) ;

folder = p.pathDataTest{1};
files = dir(fullfile(folder,p.wildCardTest{1}));
files = {files.name}';
file1 = fullfile(folder,files{1});
file2 = fullfile(folder,files{5});

symLut = GetDatasetSym(folder,p.wildCardTest{1});

%%
shape1 = load_shape_sampled(file1);
shape2 = load_shape_sampled(file2);

% shape1.X = shape1.X + 100;
shape1.Y = shape1.Y + 100;

%%
basisParams = GetBasisParams(p);
geoVec1 = FileBasis(file1);
geoVec2 = FileBasis(file2);

descBasis = trainRes.COV;
desc1.OPT = descBasis * geoVec1';
desc2.OPT = descBasis * geoVec2';

descSize = 16;
l = FileLBO(file1);
[desc1.HKS,desc1.WKS] = GetOldDescs(l.evals,l.evecs,descSize);
l = FileLBO(file2);
[desc2.HKS,desc2.WKS] = GetOldDescs(l.evals,l.evecs,descSize);
clear l descBasis geoVec1 geoVec2
%%
GetTriu = @(m)m(triu(true(size(m)),1));


nFpsSamples = 100;
fpsData1 = FileFPS(file1,nFpsSamples,symLut,1);
xDist1 = fpsData1.xDist;
fpsIdxs = fpsData1.idxs;

descNames = fieldnames(desc1);
% figure;aH = [];
% nToPlot = [75 46 61];
% nToPlot = [1 1 1]*nFpsSamples;
for d = 1:3
    curDesc = descNames{d};
    curDesc1 = desc1.(curDesc);
    curDesc2 = desc2.(curDesc);
    
%     % FPS on descriptor space
%     fpsIdxs = EuclidFPS(curDesc1, nFpsSamples, 1);
%     xDist1 = CalcCrossDist(shape1,fpsIdxs);

    diameter = max(xDist1(:));
    
    
    kNN = 20;
    xDistFun2 = @(i)CalcCrossDist(shape2,i);
    [i1_fps,i2] = SpectralMatching(curDesc1(:,fpsIdxs),curDesc2,xDist1,xDistFun2,kNN);
    
    i1 = fpsIdxs(i1_fps);
    
    %% calc distortion
    % d1 = CalcCrossDist(shape2,i1,i2);
    % d2 = CalcCrossDist(shape2,i2,i1);
    % mean(abs(diag(d2)-diag(d1)))
    
    %gtDist = abs(xDistFun2(i1)-xDist1(i1_fps,i1_fps));
    
    % xDiff = abs(xDistFun2(fpsIdxs)-xDist1);
    xDiff = abs(xDistFun2(i2)-xDist1(i1_fps,i1_fps));
%     xDiff = abs(xDistFun2(i2)-xDistFun2(i1));

    for n = 3:size(xDiff,1)
        if max(max(xDiff(1:n,1:n)))>20
            nToPlot(d) = n-1; %#ok<SAGROW>
            break
        end
    end
    

    %%
    figure(2454);clf; 
%     aH(end+1) = subplot(2,3,d); %#ok<SAGROW>
    imagesc(100*xDiff/diameter)
    axis equal tight
    set(gca,'clim',[0 20],'position',[.1 .1 .8 .8])
    if d==3
        c=colorbar;
        set(get(c,'YLabel'),'String','pairwise distortion (%)')
    end
    % hist(sum(xDiff),50)
    
    % [~,I] = sort(sum(xDiff));
    % figure;imagesc(xDiff(I,I)/diameter);axis equal

    xDiff_ = xDiff(1:nToPlot(d),1:nToPlot(d));
    xDiffVec = GetTriu(xDiff_) * 100 / diameter;
    distortion(d).mean = mean(xDiffVec); %#ok<SAGROW>
    tmp = prctile(xDiffVec,[0 10 50 90 100]);
    distortion(d).min = tmp(1); %#ok<SAGROW>
    distortion(d).p10 = tmp(2); %#ok<SAGROW>
    distortion(d).med = tmp(3); %#ok<SAGROW>
    distortion(d).p90 = tmp(4); %#ok<SAGROW>
    distortion(d).max = tmp(5); %#ok<SAGROW>
    
    set(gcf,'position',[100 100 450 300])
    title(sprintf('%s - L_\\infty=%.1f%%, %d matches',curDesc,distortion(d).max,nToPlot(d)))
%     saveas(gcf,[curDesc,'_2d.eps'],'epsc')
%     saveas(gcf,[curDesc,'_2d.png'])


    fPlot = figure(6546);
    clf;
    set(gcf,'color','w','position',[100 100 500 500])
    %cla
    hold on
    nTRIs = size(shape1.TRIV,1);
    p1 = PlotShape(shape1); 
    p2 = PlotShape(shape2); 
    set(p1,'FaceColor','b')
    set(p2,'FaceColor','r')
    view(3)
    set(gca,'position',[0 0 1 1])


    % I = fpsData1.idxs(any(xDiff>prctile(xDiffVec,99.9)));
    % [row,col,v] = find(xDiff == max(xDiff(:)))
    
    
    toPlot1 = i1(1:nToPlot(d));
    toPlot2 = i2(1:nToPlot(d));
    
    % plot lines as cylinders
    sphere = TriangulatedSphere(10);
    for i=1:nToPlot(d)
        axisPoint1 = [shape1.X(toPlot1(i)) shape1.Y(toPlot1(i)) shape1.Z(toPlot1(i))];
        axisPoint2 = [shape2.X(toPlot2(i)) shape2.Y(toPlot2(i)) shape2.Z(toPlot2(i))];
        R_ = 1;
        N_ = 10;
        [CylinderHandle] = Cylinder(axisPoint1,axisPoint2,R_,N_,'g');
        %set(CylinderHandle,'parent',hg,'displayname','corr')

        sphere1 = sphere;
        sphere1.X = 2*sphere.X + axisPoint1(1);
        sphere1.Y = 2*sphere.Y + axisPoint1(2);
        sphere1.Z = 2*sphere.Z + axisPoint1(3);
        trisurf(sphere1.TRI,sphere1.X,sphere1.Y,sphere1.Z,'facecolor',[1 1 1]/3,'edgecolor','none')
        
        sphere2 = sphere;
        sphere2.X = 2*sphere.X + axisPoint2(1);
        sphere2.Y = 2*sphere.Y + axisPoint2(2);
        sphere2.Z = 2*sphere.Z + axisPoint2(3);
        trisurf(sphere2.TRI,sphere2.X,sphere2.Y,sphere2.Z,'facecolor',[1 1 1]/2,'edgecolor','none')
    end
    
    % render
    pngName = [curDesc,'_corr.png'];
    camlight head
    lighting phong
    saveas(gcf,[curDesc,'_corr.fig'])
    saveas(gcf,pngName)
    FixAndExportToBlender(gcf, [curDesc,'_corr.wrl']);
%     fRender = myaa(6);
%     saveas(fRender,pngName)
%     close(fRender)
%     
%     % make tight
%     pngData  = imread(pngName);
%     notWhite = any(pngData<254,3);
%     pngData  = pngData(any(notWhite,2),any(notWhite,1),:);
%     notWhite = notWhite(any(notWhite,2),any(notWhite,1),:);
%     imwrite(pngData,pngName,'png','Alpha',double(notWhite));
    
end

% for a = aH(:)'
%     pos = get(a,'position');
%     set(a,'position',[pos(1:2)-.05 .3 .4])
% end



