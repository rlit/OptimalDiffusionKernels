startup
randn('seed', 0); %#ok<RAND>
rand( 'seed', 0); %#ok<RAND>

p = GetParams_LSD();

dataPath = fullfile(p.pathData ,'tosca\');
savePath = fullfile(p.pathData ,'tosca_part\');

wildCard = 'michael*.mat';
files = dir([dataPath wildCard]);
files = {files.name}';

pctToRemove = 5:5:15;
tmp = [];

for iShape = 1:numel(files)
    
    s   = load_shape(GetPrecalcFilename([dataPath files{iShape}] ,'sampled'));
    lbo = load(GetPrecalcFilename([dataPath files{iShape}] ,'lbo'),'area');
   
    nFps = 30;
    i0 = randi(numel(s.X),1);
    [fpsRes.P,fpsRes.D,fpsRes.d,fpsRes.rad] = farptsel(s.TRIV, s.X, s.Y, s.Z, nFps, i0);

    
    nSamples = 3;
    idxs = randsample(nFps,nSamples);
    D = min(fpsRes.D(:,idxs),[],2);
    
    
    [Ds,perm] = sort(D);
    As = lbo.area(perm);
    Acum = cumsum(As/sum(As));

    
    for pct = pctToRemove
        if iShape == 1
            to_keep = 1:numel(s.X);
        else
            to_keep1 = find(Acum > pct/100,1,'first');
            to_keep = perm(to_keep1:end);
        end
        
        % cut shape
        [shape,idxsKept]   = DeleteShapeVertices(s,to_keep);
        shape.pctRmoved = pct;
        shape.idxsKept  = idxsKept;
        assert(numel(shape.X)==numel(idxsKept))
        
        % save
        pctFolder = [savePath int2str(pct) '\'];
        pctFolderS = [savePath int2str(pct) '\sampled\'];
        MakeDir(pctFolderS)
        fullSavePath = [pctFolder  files{iShape}];
        save(fullSavePath,'tmp')
        save([pctFolderS files{iShape}],'shape')
        
        % calc LBO
        lbo = FileLBO(fullSavePath,[]);
        assert(numel(lbo.area)==numel(idxsKept))
        save(GetPrecalcFilename(fullSavePath,'lbo'),'idxsKept','-append')

        % plot
        figure(13466);clf
        PlotShape(shape,1)
        hold on
        scatter3(...
            s.X(fpsRes.P(idxs)),...
            s.Y(fpsRes.P(idxs)),...
            s.Z(fpsRes.P(idxs)),...
            50,'r','o','filled')
        camlight head
        lighting phong
        
        saveas(13466,[pctFolder strrep(files{iShape},'.mat','.png')],'png')
        
    end
    
    
    % figure(13466);clf
    % PlotShape(s_,1)
    % hold on
    % scatter3(...
    %     s.X(fpsRes.P(idxs)),...
    %     s.Y(fpsRes.P(idxs)),...
    %     s.Z(fpsRes.P(idxs)),...
    %     50,'r','o','filled')
    % %%
    % camlight head
    % lighting phong
end



