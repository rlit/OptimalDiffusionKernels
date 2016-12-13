
startup
if nargin < 1
    p = GetParams_LSD();
end

p.descMaxDim = 16;
p.oldDescDim = p.descMaxDim;
p.alphaVals  = 2.^(-2);


%%
p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'david*.mat';
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'victoria*.mat';
[trainRes(1),trainDataTOS] = RunTraining(p);

tripletsTOS = cell(1,3);
for k = 1:numel(trainDataTOS)
    gv    = trainDataTOS(k).geoVecs;
    tIdxs = trainDataTOS(k).tripletIdxs;
    tripletsTOS{1} = [tripletsTOS{1} ; gv(tIdxs{1},:)];
    tripletsTOS{2} = [tripletsTOS{2} ; gv(tIdxs{2},:)];
    tripletsTOS{3} = [tripletsTOS{3} ; gv(tIdxs{3},:)];
end

% nTriplesTos = sum(cellfun(@(c)numel(c{1}),{trainDataTOS.tripletIdxs}));
nTriplesTos = size(tripletsTOS{1},1);
perm = randperm(nTriplesTos)';
tripletsTOS{1} = tripletsTOS{1}(perm,:);
tripletsTOS{2} = tripletsTOS{2}(perm,:);
tripletsTOS{3} = tripletsTOS{3}(perm,:);
clear trainDataTOS

%%

p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1} = fullfile(p.pathData ,'shrec07');
wildCard = '*.mat';

files = dir(fullfile(p.pathDataTrain{1},wildCard));
files = {files.name}';
idxs = cellfun(@(s)str2double(s(1:end-4)),files);
to_run = [
    25  ...30 31 ... cup
    107 ... chair
    127 ...134 ... Octopus
    ...  table
    171 ...161 ... teddy
    191 ...183 ... hand
    248 ... bird
    275 ... spring
    285 ... armadillo
    315 ... bust
    ];
p.nTripletsPerSample = 60;p.nFpsTrain = 500;
for i = 1:numel(to_run)
    curFile = files(to_run(i)==idxs);
    assert(numel(curFile)==1,'~ one file')
    p.wildCardTrain{1} = [curFile{1} '*'];
    %     lbo = FileLBO(fullfile(p.pathDataTrain{1},curFile{1}));
    %     s = load_shape_sampled(fullfile(p.pathDataTrain{1},curFile{1}));
    %     clf;
    %     subplot(231);PlotShape(s,lbo.evecs(:,2)); shading interp
    %     subplot(232);PlotShape(s,lbo.evecs(:,3)); shading interp
    %     subplot(233);PlotShape(s,lbo.evecs(:,4)); shading interp
    %     subplot(234);PlotShape(s,lbo.evecs(:,5)); shading interp
    %     subplot(235);PlotShape(s,lbo.evecs(:,6)); shading interp
    %     subplot(236);PlotShape(s,lbo.evecs(:,7)); shading interp
    %     drawnow expose
    %     pause
    [~,trainDataS07(i)] = RunTraining(p); %#ok<SAGROW>
    
    %     fprintf('\t %d/%d - %s \n\n\n',i,numel(to_run),curFile{1})
end
p.nTripletsPerSample = 75;p.nFpsTrain = 1000;

tripletsS07 = cell(1,3);
for k = 1:numel(trainDataS07)
    gv    = trainDataS07(k).geoVecs;
    tIdxs = trainDataS07(k).tripletIdxs;
    tripletsS07{1} = [tripletsS07{1} ; gv(tIdxs{1},:)];
    tripletsS07{2} = [tripletsS07{2} ; gv(tIdxs{2},:)];
    tripletsS07{3} = [tripletsS07{3} ; gv(tIdxs{3},:)];
end

% nTriplesS07 = sum(cellfun(@(c)numel(c{1}),{trainDataS07.tripletIdxs}));
nTriplesS07 = size(tripletsS07{1},1);
clear trainDataS07 gv tIdxs to_run


%%



p.pathDataTest  = {};
p.wildCardTest  = {};
p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
p.wildCardTest{end+1}  = 'michael*.mat';

folder = [datestr(now,'yyyy-mm-dd_HH-MM-SS') '_Pertubation\'];
% RunTest(p,trainRes,[folder num2str(100)]); close all


pcts = .1:.1:.9;
trainRes(numel(pcts)+1) = trainRes(1); 
for i = numel(pcts)
    
    nSamplesTos = ceil(nTriplesTos*pcts(i));
    smplTOS = randsample(nSamplesTos,nSamplesTos);
    smplS07 = randsample(nTriplesS07,nTriplesTos - nSamplesTos);
    
    curTriplets = cellfun(@(a,b){[a(smplTOS,:) ; b(smplS07,:)]},tripletsTOS,tripletsS07);
    
    allGeoVecs = unique(vertcat(curTriplets{:}),'rows');
    [~,allTripletIdxs] = cellfun(@(x)ismember(x,allGeoVecs, 'rows'),curTriplets, 'UniformOutput' , false);
    
    trainRes(i) = trainRes(1); 
    trainRes(i).COV = OptimizeMoments({allGeoVecs},{allTripletIdxs},trainRes(1).alpha,p.descMaxDim);
    
    %RunTest(p,trainRes,[folder num2str(100*pcts(i))]); close all
    
    fprintf('\t %d/%d - %.0f%% \n\n',i,numel(pcts),100*pcts(i))
    
end
%%

RunTest(p,trainRes,folder); 

%%

c = get(gca,'children');
n = get(c,'DisplayName');
is = strncmp(n,'OPT',3);
d = get(c,'yData');
p1 = cellfun(@(d)d(1),d);
p10= cellfun(@(d)d(10),d);

figure(3256);clf
hold on
x = 0:10:90;
plot(x,               p1(is)     ,'b-o','DisplayName','Best match - OPT','linewidth',2)
plot(x,ones(size(x))* p1(end-1)  ,'r-x','DisplayName','Best match - HKS','linewidth',2)
plot(x,ones(size(x))* p1(end  )  ,'g-+','DisplayName','Best match - WKS','linewidth',2)
plot(x,               p10(is)   ,'ob--','DisplayName','10^{th} match - OPT','linewidth',2)
plot(x,ones(size(x))* p10(end-1),'xr--','DisplayName','10^{th} match - HKS','linewidth',2)
plot(x,ones(size(x))* p10(end  ),'+g--','DisplayName','10^{th} match - WKS','linewidth',2)

xlabel('% of contaminated data')
ylabel('Hitrate (%)')
legend show location best
