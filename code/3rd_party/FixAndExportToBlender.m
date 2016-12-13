function FixAndExportToBlender(h, filename)
assert(ishandle(h))
axesH = findobj('type','axes','-and','parent',h);

%% delete light object
lightObj = findobj('type','light','-and','parent',axesH);
if ishandle(lightObj)
    set(lightObj,'position',[1 5 1])
end

%% fit to unit box & rotate
pathces = [findobj('type','patch','-and','parent',axesH);
 findobj('type','surface','-and','parent',axesH)];
% lines   = findobj('type','line','-and','parent',axesH);
% childObjs = [pathces ; lines];
childObjs = get(axesH,'Children');

patchNames = get(pathces,'displayname');
isAnnotation = strcmp('reflection_plane',patchNames) | strcmp('rotation_axis',patchNames);
[bounds.minX,bounds.maxX] = GetBounds(get(pathces(~isAnnotation),'XData'));
[bounds.minY,bounds.maxY] = GetBounds(get(pathces(~isAnnotation),'YData'));
[bounds.minZ,bounds.maxZ] = GetBounds(get(pathces(~isAnnotation),'ZData'));
bounds.scaleMax = max([
    bounds.maxX-bounds.minX
    bounds.maxY-bounds.minY
    bounds.maxZ-bounds.minZ]);

for o = 1:numel(childObjs)
    FixObj(childObjs(o),bounds);
end

axis([0 1 0 1 0 1 ])
axis off
%%
set(axesH,'cameraPosition', [2 2 2])
% set(axesH,'cameraViewAngle')
set(axesH,'cameraUpVector',[0 1 0])
set(axesH,'cameraTarget',[.5 .5 .5])

%% add white floor
plane.vertices = [1 0 1 ; -1 0 1 ; -1 0 -1 ; 1 0 -1]*10;
plane.faces = [1 2 3; 1 3 4];
patch(plane,'facecolor','w','edgecolor','none');



exportToBlender(h,filename)
%%

return
%%
blenderPath = 'C:\Program Files\Blender Foundation\Blender\blender.exe';
importScriptPath = 'C:\Users\Litman\Desktop\importFromMatlab.py';
blendFilePath = 'C:\Users\Litman\Desktop\empty.blend';
renderPath = '//img1';
command = [
 '"' blenderPath ...
 '" -b "' blendFilePath ...
 '" -P "' importScriptPath...
 '" -o "' renderPath ...
 '"  -F PNG -x 1'];
[status,result] = system(command,'-echo');

function [minVal,maxVal] = GetBounds(valsIn)
if iscell(valsIn)
minVal = cellfun(@(v)min(v(:)),valsIn);
minVal = min(minVal);
maxVal = cellfun(@(v)max(v(:)),valsIn);
maxVal = max(maxVal);
else
minVal = min(valsIn(:));
maxVal = max(valsIn(:));
end
function FixObj(obj,bounds)
switch get(obj,'type')
    case 'patch'
        %%
        V = get(obj,'Vertices');
        
        %fix scale
        V = bsxfun(@minus  ,V,[bounds.minX,bounds.minY,bounds.minZ]);
        V = bsxfun(@rdivide,V,bounds.scaleMax);
        
        %fix oreintation
        tmp = V(:,2);
        V(:,2) = V(:,3);
        V(:,3) = -tmp+1;
        V(:,1) = V(:,1)+.5;

        
        set(obj,'Vertices',V);
        
    case {'line','surface'}
        %%
        %fix scale
        V = get(obj,'XData');V=V-bounds.minX; V = V/bounds.scaleMax; set(obj,'XData',V);
        V = get(obj,'YData');V=V-bounds.minY; V = V/bounds.scaleMax; set(obj,'YData',V);
        V = get(obj,'ZData');V=V-bounds.minZ; V = V/bounds.scaleMax; set(obj,'ZData',V);
        
        %fix oreintation
        tmp = get(obj,'YData');
        set(obj,'YData',get(obj,'ZData'));
        set(obj,'ZData',-tmp+1)
        set(obj,'XData',get(obj,'XData')+.5);
        
    case 'light'
    case 'text'
    otherwise
        error('unkown type')
end

