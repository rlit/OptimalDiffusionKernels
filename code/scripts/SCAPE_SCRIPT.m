folder = fullfile(p.pathData ,'scape');

d = dir([folder  '\*.ply']);

for ii = 1:numel(d)
    resName = [folder  '\' strrep( d(ii).name,'ply','mat')];
    if exist(resName,'file')
        continue
    end
    shape = load_shape([folder  '\' d(ii).name]);
    
    t       =  shape.X;
    shape.X =  shape.Z;
    shape.Y = -shape.Y;
    shape.Z = t;
    
    [~, evals] = CalcLBO(shape);
    shape = ScaleShape(shape,sqrt(evals(end)/.12));
    %shape = ScaleShape(shape,90);
    
    save(resName,'shape')
end

%%
d = dir([folder  '\*.mat']);

pngDir = fullfile(folder,'PNGs');
if ~isdir(pngDir), mkdir(pngDir),end

fPlot = figure('color','w','renderer','zbuffer','units','pixels','position',[100 100 550 550]);
colormap(0.9*[1 .95 0.85])

for ii = 1:numel(d)
    
    pngName = [pngDir  '\' strrep( d(ii).name,'mat','png')];
    if exist(pngName,'file')
        %continue
    end
    l = load([folder  '\' d(ii).name]);
    
    clf(fPlot)
    a = axes('parent',fPlot,'units','normalized','position',[0 0 1 1]);

    
    PlotShape(l.shape)
    %PlotShape(RotateShape(l.shape,0,-pi/2,pi/2))
    view(3)
    light;
    lighting phong;
    camlight head;
    
    saveas(fPlot,pngName)
    continue

    % render
    pngName = [pngDir  '\' strrep( d(ii).name,'mat','png')];
    fRender = myaa(6);
    saveas(fRender,pngName)
    close(fRender)

end
%%
close all