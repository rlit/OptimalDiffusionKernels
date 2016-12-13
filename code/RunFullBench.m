function RunFullBench

startup
if nargin < 1 
    p = GetParams_LSD();
end

folder = [datestr(now,'yyyy-mm-dd_HH-MM-SS') '_FullBench\'];
folder = '2013-06-11_15-03-36_FullBench'
p.descMaxDim = 16;
p.oldDescDim = p.descMaxDim;

%%
% p.alphaVals  = 2.^( -3:.25:-1);
p.alphaVals  = 2.^(-2);

p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'david*.mat';
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'victoria*.mat';
trainResTosca = RunTraining(p);

p.pathDataTest  = {};
p.wildCardTest  = {};
p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
p.wildCardTest{end+1}  = 'michael*.mat';
RunTest(p,trainResTosca,[folder 'TOSCA_on_TOSCA']); close all


%% partiality test

partRoot = fullfile(p.pathData ,'tosca_part');
if isdir(partRoot)
    pcts = dir(partRoot);
    pcts = pcts([pcts.isdir] & ~strncmp({pcts.name},'.',1));
    
    p.wildCardTest = {'michael*.mat'};
    
    for pct = {pcts.name}
        p.pathDataTest = {fullfile(p.pathData ,['tosca_part\' pct{1}])};
        RunTest(p,trainResTosca,[folder 'TOSCA_on_TOSCA_PART\'  pct{1}]); close all
        
    end
end

%%
% selected alpha value
p.alphaVals  = 2.^(-2);

% keep only selected alpha value in trainResTosca
trainResTosca = trainResTosca(p.alphaVals==[trainResTosca.alpha]);

p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
p.wildCardTrain{end+1}  = 'mesh05*.mat';
p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
p.wildCardTrain{end+1}  = 'mesh02*.mat';
trainResScape = RunTraining(p);

p.pathDataTest  = {};
p.wildCardTest  = {};
p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
p.wildCardTest{end+1}  = 'mesh0*.mat';
p.removeTrainFromTest = 1;
RunTest(p,trainResTosca,[folder 'TOSCA_on_SCAPE']); close all
RunTest(p,trainResScape,[folder 'SCAPE_on_SCAPE']); close all

% collect graphs
CollectGraphs(fullfile(p.pathData,'perf_plots',folder),'cmc')
CollectGraphs(fullfile(p.pathData,'perf_plots',folder),'RocP')


%% Plot Similarity maps
p.oldDescDim = 16;

p.pathDataTest  = {};
p.wildCardTest  = {};
p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
p.wildCardTest{end+1}  = 'michael*.mat';
p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
p.wildCardTest{end+1}  = 'mesh03*.mat';

strs = {'wrist','elbow','index_finger','head_top','foot_thumb','nipple','belly'};
idxs = [3988   ,3716   ,4353          ,2055      ,8031        ,709     ,534 ];
for i = [1 6 7]%1:numel(idxs)
    PlotAllSimMaps(p,trainResTosca,[folder 'Similarity_Maps\' strs{i}],idxs(i))
end


function CollectGraphs(folder,figName)
%%
pth1 = fullfile(folder,'TOSCA_on_SCAPE');
pth2 = fullfile(folder,'SCAPE_on_SCAPE');

f1 = open(fullfile(pth1,[figName '.fig']));
h1 = findobj('type','line','-and','parent',gca);
f2 = open(fullfile(pth2,[figName '.fig']));
h2 = findobj('type','line','-and','parent',gca);

isOpt = ~cellfun(@isempty,strfind(get(h2,'displayname'),'OPT')) ;
set(h2(isOpt),'displayname','OPT SCAPE');

isOpt = ~cellfun(@isempty,strfind(get(h1,'displayname'),'OPT')) ;
set(h1(isOpt),'parent',get(f2,'CurrentAxes'),'color','m','displayname','OPT TOSCA');

legend show location best
close(f1)
saveas(f2,fullfile(folder,[figName '_SCAPE.fig']))
close(f2)

% function [f,h] = LoadGraph(folder,figName)
% f = open(fullfile(folder,[figName '.fig']));
% h = findobj('type','line','-and','parent',gca);
% isOpt = ~cellfun(@isempty,strfind(get(h2,'displayname'),'OPT')) ;
% h = h(isOpt);
