startup
p = GetParams_LSD();

p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'david*.mat';
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'victoria*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh05*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh02*.mat';


p.alphaVals  = 2.^(-2);


% run training
trainRes = RunTraining(p);


%%

p.pathDataTest  = {};
p.wildCardTest  = {};
p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
p.wildCardTest{end+1}  = 'michael*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTest{end+1}  = 'mesh0*.mat';
p.removeTrainFromTest = 1;

dims = 4:4:100;
trainResCOV = trainRes.COV;
for d = 1:numel(dims)
    curDim = dims(d);
    p.descMaxDim = curDim;
    p.oldDescDim = curDim;
    
    covDim = min(size(trainResCOV,1) , curDim);
    trainRes.COV = trainResCOV(1:covDim,:);
    
    allPerf = BenchDescs(trainRes,p);

    tmp = [allPerf.optCov];
    cmc.Cov(:,d) = mean([tmp.cmc],2);
    
    tmp = [allPerf.Hks];
    cmc.Hks(:,d) = mean([tmp.cmc],2);
    
    tmp = [allPerf.Wks];
    cmc.Wks(:,d) = mean([tmp.cmc],2);

end

clear allPerf
nVert = [tmp.nVert];
assert(all(nVert(1) == nVert))
cmcX = 100*(1:size(cmc.Cov,1))/nVert(1);

save test_dimensions_
%%
return
%% 3d plot
figure(234)
clf
hold on
surf(dims,cmcX',cmc.Hks,'facecolor','r','edgecolor','none')
surf(dims,cmcX',cmc.Wks,'facecolor','g','edgecolor','none')
surf(dims,cmcX',cmc.Cov,'facecolor','b','edgecolor','none')
view(-130,30)

% surf(dims,cmcX',cmc.Hks,'facecolor','none','edgecolor','r')
% surf(dims,cmcX',cmc.Wks,'facecolor','none','edgecolor','g')
% surf(dims,cmcX',cmc.Cov,'facecolor','none','edgecolor','b')

legend Hks Wks Opt location south
xlabel('# of dimensions')
ylabel('% of best matches')
zlabel('hit-rate')
% zlim([.2 .8])
grid on
axis tight
camlight head
light 

%% CMC-diff
f=figure(255);
clf
minmax = @(v)[min(v) max(v)];
img = 100*(cmc.Cov-cmc.Wks);
imagesc(img','XData',minmax(cmcX),'YData',minmax(dims))
set(gca,'clim',[0 20])
axis xy

ylabel('# of dimensions')
xlabel('% of best matches')

h=colorbar ;
set(get(h,'YLabel'),'String','OPT hitrate - WKS hitrate (%)')

saveas(f,'CMC_diff.fig')
saveas(f,'CMC_diff.eps','epsc')

%% multiple CMCs
f = figure(23);
clf
hold on
d2plot = [8 32 64];
lin = {'--','-.','-',':'};
% mrk = {'+','x','o','p'};
h = [];
for i = 1:numel(d2plot)
    curD   = d2plot(i);
    d      = find(curD == dims);
    curStr = sprintf('- # of dim=% 2d',curD);
%     plot(cmcX(1:4:end),cmc.Cov(1:4:end,d),'Marker',mrk{i},'linewidth',2,'color','b','displayname',['Opt ' curStr])
%     plot(cmcX(1:4:end),cmc.Hks(1:4:end,d),'Marker',mrk{i},'linewidth',2,'color','r','displayname',['Hks ' curStr])
%     plot(cmcX(1:4:end),cmc.Wks(1:4:end,d),'Marker',mrk{i},'linewidth',2,'color','g','displayname',['Wks ' curStr])
    h(i+2*numel(d2plot)) = plot(cmcX,100*cmc.Hks(:,d),'LineStyle',lin{i},'linewidth',2,'color','r','displayname',['HKS ' curStr]);
    h(i+1*numel(d2plot)) = plot(cmcX,100*cmc.Wks(:,d),'LineStyle',lin{i},'linewidth',2,'color','g','displayname',['WKS ' curStr]);
    h(i+0*numel(d2plot)) = plot(cmcX,100*cmc.Cov(:,d),'LineStyle',lin{i},'linewidth',2,'color','b','displayname',['OPT ' curStr]);
end
set(gca,'children',h)
xlabel('% of best matches')
ylabel('hit-rate (%)')
legend show location best

saveas(f,'CMC_per_dim.fig')
saveas(f,'CMC_per_dim.eps','epsc')


%% Precision@1
figure(239)
clf
hold on

%lin = {'--','-.',':','-'};
mrk = {'+','x','o','p'};
plot(dims(2:end),100*cmc.Hks(1,2:end),'-','linewidth',2,'color','r','displayname','Hks')
plot(dims(2:end),100*cmc.Wks(1,2:end),'-','linewidth',2,'color','g','displayname','Wks')
plot(dims(2:end),100*cmc.Cov(1,2:end),'-','linewidth',2,'color','b','displayname','Opt')
xlabel('# of dimensions')
ylabel('% of correct 1^{st} matches')
grid on
legend show location best