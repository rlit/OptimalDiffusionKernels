function exportToBlender(h,filename)
%   Saves the h figure to VRML 2.0 file so that it can be loaded
%   by Blender
%   Example:
%   exportToBlender(gcf, 'figure1.wrl');
%
%   Notes:
%    (*) The shading must be flat, i.e: 'shading flat';
%
%   This file is a modification of the vrml.m file from matlab
%   R. Paxson, 4-10-97.
%   Copyright 1984-2006 The MathWorks, Inc.
%   $Revision: 1.14.4.7 $
%
%   @author Jonathan Pokrass
%

global VRML_OUTPUT_FILE;

switch nargin
case 0
   error(id('minrhs'),'Not enough input arguments');
case 1
   filename = 'matlab.wrl';
case 2
  if ischar(filename)
      [pathstr,name,ext] = fileparts(filename);
      if isempty(ext)
          ext = '.wrl';
      end
      filename = fullfile(pathstr,[name,ext]);
  else
      error(id('InvalidFileName'), 'Filename argument is not a string');
  end
end

if ~any(ishghandle(h))
   error(id('InvalidObjectHandle'), 'First argument must be a valid object handle');
end

VRML_OUTPUT_FILE = fopen(filename,'w');
try
    WriteFileHeaderAndInfo;
    ProcessObject(h);
    fclose(VRML_OUTPUT_FILE);
    clear global VRML_OUTPUT_FILE
catch err
    fclose(VRML_OUTPUT_FILE);
    clear global VRML_OUTPUT_FILE
    delete(filename);
    rethrow(err)
end

function WriteFileHeaderAndInfo()
  sendStr(0,'#VRML V2.0 utf8\n');
  sendStr(0,'WorldInfo {title "Matlab-VRML"}\n');
  sendStr(0,'NavigationInfo {\n');
  sendStr(1,'headlight FALSE\n');
  sendStr(1,'type "EXAMINE"\n');
  sendStr(0,'}\n');

function ProcessObject(obj_handle)
  obj = get(obj_handle);
  switch obj.Type
    case 'figure',  HandleFigure( obj);
    case 'axes',    HandleAxes(   obj_handle);
    case 'light',   HandleLight(  obj);
    case 'patch',   HandlePatch(  obj_handle);
    case 'surface', HandleSurface(obj_handle);
    case 'line',    HandleLine(   obj);
    case 'image',   HandleImage(  obj);
    case 'text',    HandleText(   obj);
  end

function HandleFigure(obj)
  if(strcmp(obj.Visible,'on'))
    sendStr(0,'Background {\n');
    sendStr(1,sprintf('skyColor [%f %f %f]\n',obj.Color));
    sendStr(0,'}\n');
    for i=1:length(obj.Children)
      ProcessObject(obj.Children(i));
    end
  end

function HandleAxes(obj_handle)
  obj = get(obj_handle);
  global VRML_USE_MATERIAL_PROPS;
  sendStr(0,'Transform {\n');
  %TODO sendStr(1,sprintf('scale %f %f %f\n',obj.PlotBoxAspectRatio./obj.DataAspectRatio));
  sendStr(1,'children [\n');
  sendStr(2,'Transform {\n');
  %TODO sendStr(3,sprintf('translation %f %f %f\n',[-sum(obj.XLim)/2 -sum(obj.YLim)/2 -sum(obj.ZLim)/2]));
  sendStr(3,'children [\n');
  sendStr(2,'Viewpoint {\n');
  sendStr(3,sprintf('position %f %f %f\n',obj.CameraPosition));
  sendStr(3,sprintf('fieldOfView %f\n',obj.CameraViewAngle*pi/180));
  % if(~feature('HGUsingMatlabClasses'))
               axesXForm = get(obj_handle, 'XForm');
  %      else
  %             axesXForm = getAxesTransformationMatrix(obj_handle);
  % end
  sendStr(3,sprintf('orientation %f %f %f %f\n',computeOrientationFromCamera(obj.CameraPosition, obj.CameraTarget, obj.CameraUpVector)));
  sendStr(3,'description "Original"\n');
  sendStr(2,'}\n');

  if(strcmp(obj.Visible,'on'))
     outputAxesCube(obj);
     outputAxesTicks(obj);
     outputAxesTickLabels(obj);
  end

  VRML_USE_MATERIAL_PROPS = 0;
  if ~isempty(findobj(obj_handle,'Type','light','Visible','on'))
     VRML_USE_MATERIAL_PROPS = 1;
  end
  for i=1:length(obj.Children)
     ProcessObject(obj.Children(i));
  end

  sendStr(3,']\n');
  sendStr(2,'}\n');
  sendStr(1,']\n');
  sendStr(0,'}\n');

  clear global VRML_USE_MATERIAL_PROPS

function HandleLight(obj)
  if(strcmp(obj.Visible,'on'))
     switch obj.Style
     case 'infinite'
        sendStr(2,'DirectionalLight {\n');
        sendStr(3,sprintf('direction %f %f %f\n',obj.Position));
     case 'local'
        sendStr(2,'PointLight {\n');
        sendStr(3,sprintf('location %f %f %f\n',obj.Position));
     otherwise
        error(id('InvalidLightMode'),'Unknown light mode in HandleLight');
     end
     % Define the intensity of the ambient light as 0.3, determined
     % empirically.
     sendStr(3,'ambientIntensity 0.3\n');
     sendStr(3,sprintf('color %f %f %f\n',obj.Color));
     sendStr(2,'}\n');
  end

function HandleText(obj)
  % check to see what kind of object we received
  % a real HG object or maybe just a label of the axis.
  field = fieldnames(obj);
  if strcmp(field{1},'String');
     % we have a ticklabel;
     sendStr(2,'Transform {\n');
     sendStr(3,sprintf('translation %f %f %f\n',obj.Position));
     sendStr(3,'children [\n');
     BeginShape('Text');
     sendStr(5,sprintf('string ["%s"]\n',obj.String));
     sendStr(5,'fontStyle FontStyle {\n');
     sendStr(6,'size 0.07\n');
     sendStr(6,'justify "MIDDLE"\n');
     sendStr(5,'}\n');
     EndShape;
     sendStr(3,']\n');
     sendStr(2,'}\n');
  else
     % we have a text object;
     sendStr(2,'Transform {\n');
     sendStr(3,sprintf('translation %f %f %f\n',obj.Position));
     sendStr(3,'children [\n');
     BeginShape('Text');
     sendStr(5,sprintf('string ["%s"]\n',obj.String));
     sendStr(5,'fontStyle FontStyle {size 0.07}\n');
     EndShape;
     sendStr(3,']\n');
     sendStr(2,'}\n');
  end

function HandlePatch(obj_handle)
  handler.coord      = 'patchCoord';
  handler.coordIndex = 'patchCoordIndex';
  handler.color      = 'patchColor';
  handler.colorIndex = 'patchColorIndex';
  HandlePatch_SurfaceObjs(obj_handle, handler);

function HandleSurface(obj_handle)
  handler.coord      = 'surfCoord';
  handler.coordIndex = 'surfCoordIndex';
  handler.color      = 'surfColor';
  handler.colorIndex = 'surfColorIndex';
  HandlePatch_SurfaceObjs(obj_handle, handler);

function HandlePatch_SurfaceObjs(obj_handle,info)
  obj = get(obj_handle);
  handle_str = sprintf('%s%g',deblank(obj.Type),double(obj_handle));
  handle_str = abs(handle_str);
  h = find(handle_str == '.');
  handle_str(h) = []; %#ok
  handle_str = char(handle_str);
  DEFINED_OBJ_COORD = 0;

  if(strcmp(obj.Visible,'on'))
     % Handle FaceColor mode
     if ~strcmp(obj.FaceColor,'none')
        BeginShape('IndexedFaceSet',obj.FaceAlpha);
        sendStr(3,'solid FALSE\n');
        coord(obj,info.coord,handle_str,'define');
        DEFINED_OBJ_COORD = 1;
        coordIndex(obj,info.coordIndex);
        facecolor(obj,info.color,obj.FaceColor);
        if ~ischar(obj.FaceColor)
           sendStr(3,'colorPerVertex FALSE\n');
        else
           switch obj.FaceColor
           case 'flat'
              sendStr(3,'colorPerVertex TRUE\n');
              colorIndex(obj,info.colorIndex,'flat');
           case 'interp'
              sendStr(3,'colorPerVertex TRUE\n');
              colorIndex(obj,info.colorIndex,'interp');
           case 'texturemap'
           otherwise
              error(id('InvalidFaceColor'),'Unknown FaceColor type in Handle Patch');
           end
        end
        EndShape;
     end
     % Handle EdgeColor mode
     if ~strcmp(obj.EdgeColor,'none')
        BeginShape('IndexedLineSet');
        if DEFINED_OBJ_COORD == 1
           coord(obj,info.coord,handle_str,'use');
        else
           coord(obj,info.coord);
        end
        coordIndex(obj,info.coordIndex);
        color(obj,info.color,obj.EdgeColor);
        if ~ischar(obj.EdgeColor)
           sendStr(3,'colorPerVertex FALSE\n');
        else
           switch obj.EdgeColor
           case 'flat'
              sendStr(3,'colorPerVertex TRUE\n');
              colorIndex(obj,info.colorIndex,'flat');
           case 'interp'
              sendStr(3,'colorPerVertex TRUE\n');
              colorIndex(obj,info.colorIndex,'interp');
           otherwise
              error(id('InvalidEdgeColor'),'Unknown EdgeColor type in Handle Surface');
           end
        end
        EndShape;
     end
  end

function HandleLine(obj)
  if(strcmp(obj.Visible,'on'))
    BeginShape('IndexedLineSet');
    coord(obj,'lineCoord');
    coordIndex(obj,'lineCoordIndex');
    color(obj,'lineColor',obj.Color);
    sendStr(4,'colorPerVertex FALSE\n');
    EndShape;
  end

% TODO: experimental version of the Image object
% the browser motion keys are much faster if the
% object is in the scale 0 -> 1 so we might want to do this
% it is most notable with images.
function HandleImage(obj)
  if(strcmp(obj.Visible,'on'))
    sendStr(2,'Shape {\n');
    sendStr(3,'appearance Appearance {\n');
    texture(obj);
    sendStr(2,'}\n');

    sendStr(3,'geometry IndexedFaceSet {\n');
    sendStr(4,'coord Coordinate { \n');
    sendStr(5,'point [\n');
    x = [obj.XData(1) obj.XData(end)];
    y = [obj.YData(1) obj.YData(end)];
    ins = [x(1) y(1);x(2) y(1);x(2) y(2);x(1) y(2)];
    sendStr(6,sprintf('%d %d 0,',ins'));
    sendStr(5,'] }\n');
    sendStr(4,'coordIndex [0, 1, 2, 3, -1]\n');
    sendStr(4,'texCoord TextureCoordinate {\n');
    sendStr(5,'point [0 0,1 0,1 1,0 1]\n');
    sendStr(4,'}\n');
    sendStr(3,'}\n');
    sendStr(2,'}\n');
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%  VRML Node Generation  %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: would like to abstract appearance node out of here.
function BeginShape(type,alpha)
  if nargin<2,alpha=1;end
  global VRML_USE_MATERIAL_PROPS;
  sendStr(2,'Shape {\n');
  if(VRML_USE_MATERIAL_PROPS)
    sendStr(3,['appearance Appearance {material Material{transparency ' num2str(1-alpha) '}}\n']);
  end
  sendStr(3,sprintf('geometry %s {\n',type));

function EndShape
  sendStr(3,'}\n');  % closes geometry node
  sendStr(2,'}\n');  % closes Shape node

% fcn:   function pointer used to provide color data
% type:  flat, interp, texture, ColorSpec.
function color(hgObj,fcn,type)
  sendStr(4,'color Color {\n');
  sendStr(5,'color [\n');
  if ~ischar(type)
     sendStr(6,sprintf('%d %d %d',type));
  else
     feval(fcn,hgObj);
  end
  sendStr(5,'\n');
  sendStr(5,']\n');
  sendStr(4,'}\n');

% fcn:   function pointer used to provide color data
% type:  flat, interp, texture, ColorSpec.
function facecolor(hgObj,fcn,type)
  sendStr(4,'color Color {\n');
  sendStr(5,'color [\n');
  if ~ischar(type) && isfield(hgObj,'Faces')
      sendStr(6,repmat(sprintf('%d %d %d\n',type),1,length(hgObj.Faces)));
  else
     feval(fcn,hgObj);
     sendStr(5,'\n');
  end
  sendStr(5,']\n');
  sendStr(4,'}\n');

% Outputs a VRML coord node.
function coord(hgObj,fcn,name,usage)
  if nargin > 2
     if strcmp(usage,'define')
        sendStr(4,sprintf('coord DEF %s Coordinate{\n',name ));
        sendStr(5,'point [\n');
        feval(fcn,hgObj);
        sendStr(5,']');
        sendStr(4,'}\n');
     elseif strcmp(usage,'use')
        sendStr(4,sprintf('coord USE %s\n',name));
     end
  else
     sendStr(4,'coord Coordinate{\n');
     sendStr(5,'point [\n');
     feval(fcn,hgObj);
     sendStr(5,']');
     sendStr(4,'}\n');
  end

function coordIndex(hgObj,fcn)
  sendStr(4,'coordIndex [\n');
  feval(fcn,hgObj);
  sendStr(4,']\n');

% need to make a node of colorIndex to have name and usage
% make sense. That could use DEF and USE as well.
function colorIndex(hgObj,fcn,type)
  sendStr(4,'colorIndex [\n');
  feval(fcn,hgObj,type);
  sendStr(4,']\n');

function texture(hgObj)
  sendStr(4,'texture PixelTexture { \n');
  sendStr(5,'repeatS FALSE\n');
  sendStr(5,'repeatT FALSE\n');
  sendStr(5,sprintf('image %d %d 3\n',size(hgObj.CData,2), size(hgObj.CData,1)));
  if ndims(hgObj.CData) == 2
    cmap = round(get(get(hgObj.Parent,'Parent'),'Colormap') * 255);
    cdata = (hgObj.CData - 1); cdata = cdata*(length(cmap)-1)/max(max(cdata));
    cdata = round(cdata' + 1);
    sendStr(6,sprintf('0x%.2x%.2x%.2x ',cmap(cdata,:)'));
  else
    error(id('RGBTexturesNotSupported'),'RGB Textures not supported yet');
  end
  sendStr(0,'\n');
  sendStr(3,'}\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Per node output utils %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function surfColor(obj)
  if ndims(obj.CData) == 2
     outputColormap(get(get(obj.Parent,'Parent'),'Colormap'));
  else
     error(id('RGBTexturesNotSupported'),'Not dealing with rgb data yet'); % TODO
  end

function patchColor(obj)
  if ndims(obj.FaceVertexCData) < 3
     outputColormap(get(get(obj.Parent,'Parent'),'Colormap'));
  else
     error(id('RGBTexturesNotSupported'),'Not dealing with rgb data yet'); %TODO
  end

function surfCoordIndex(obj)
  [rows cols] = size(obj.ZData);
  for i=0:rows-2
     for j=0:cols-2
        curr = i + j*rows;
        %sendStr(5,sprintf('%d,%d,%d,%d,-1\n',[curr curr+rows curr+rows+1 curr+1]));
        sendStr(5,sprintf('%d,%d,%d,%d,-1\n',[curr+rows curr curr+1 curr+rows+1]));
     end
  end

% pax I will need to come and optimize this
% for not this is ok but need to handle nan and those
% kind of things.
function patchCoordIndex(obj)
  nvert = size(obj.Faces,2);
  str = '%d,';
  nstr = abs(str)'*ones(1,nvert);
  nstr = [char(nstr(:)') '-1\n'];
  sendStr(5,sprintf(nstr,obj.Faces'-1));

function patchColorIndex(obj,type)
  len = length(get(get(obj.Parent,'Parent'),'Colormap'));
  cdat = colorMapping(obj.FaceVertexCData, get(obj.Parent,'Clim'), len, obj.CDataMapping);
  cdat = cdat + 1;
  switch type
  case 'flat'
    sendStr(5,sprintf('0,\n'));
    sendStr(5,sprintf('%d,\n',cdat));
  case 'interp'
    sendStr(5,sprintf('0,\n'));
    sendStr(5,sprintf('%d,\n',cdat));
    %error(id('InterpolatedColorsNotSupported'),...
    %      'Interpolated colors in patch object not supported yet by vrml.m');
  otherwise
     error(id('InvalidColorType'),'Unknown color type in patchColorIndex');
  end

% this guy will have to listen to CDataScaling and Mapping and so forth pax
function surfColorIndex(obj,type)
  switch type
  case 'flat'
     [rows cols] = size(obj.CData);
     cmap_len = length(get(get(obj.Parent,'Parent'),'Colormap'));
     cdat = colorMapping(obj.CData, get(obj.Parent,'Clim'), cmap_len, obj.CDataMapping);
     for i=1:rows-1
        for j=1:cols-1
           sendStr(5,sprintf('%d,\n',cdat(i,j)));
        end
     end
  case 'interp'
     [rows cols] = size(obj.CData);
     cmap_len = length(get(get(obj.Parent,'Parent'),'Colormap'));
     cdat = colorMapping(obj.CData, get(obj.Parent,'Clim'), cmap_len, obj.CDataMapping);
     for i=1:rows-1
        for j=1:cols-1
           curr = i + (j-1)*rows;
           sendStr(5,sprintf('%d,%d,%d,%d,-1\n',cdat([curr curr+rows curr+rows+1 curr+1])));
        end
     end
  otherwise
     error(id('InvalidColorIndexType'),'Unknown colorIndex type in surfColorIndex');
  end

function lineCoord(obj)
  if(isempty(obj.ZData))
     for i=1:length(obj.XData)
        sendStr(6,sprintf('%f %f %f,\n',[obj.XData(i) obj.YData(i) 0]));
     end
  else
     for i=1:length(obj.XData)
        sendStr(6,sprintf('%f %f %f,\n',[obj.XData(i) obj.YData(i) obj.ZData(i)]));
     end
  end

function lineCoordIndex(obj)
  sendStr(5,'');
  for i=1:length(obj.XData)
     sendStr(1,sprintf('%d, ',i-1));
  end
  sendStr(1,'-1\n');

function surfCoord(obj)
  if(all(size(obj.ZData)==size(obj.XData)) && all(size(obj.ZData)==size(obj.YData)))
     d = [obj.XData(:)'; obj.YData(:)'; obj.ZData(:)'];
  else
     [x y] = meshgrid(obj.XData,obj.YData);
     d = [x(:)'; y(:)'; obj.ZData(:)'];
  end
  sendStr(6,sprintf('%f %f %f,\n',d));

function patchCoord(obj)
  if size(obj.Vertices,2) == 2
     sendStr(6,sprintf('%f %f 0.0,\n',obj.Vertices'));
  else
     sendStr(6,sprintf('%f %f %f,\n',obj.Vertices'));
  end

% could use scalar expansion here.
function axesTickCoord(obj)
  % XTICK
  tx = .05;
  x = obj.XTick';
  y = obj.YLim(1)*ones(length(x),1);
  z = obj.ZLim(1)*ones(length(x),1);
  xticks = [x y z ;x y+tx z];
  sendStr(6,sprintf('%f %f %f,\n',xticks'));

  % YTICK
  ty = .05;
  y = obj.YTick';
  x = obj.XLim(1)*ones(length(y),1);
  z = obj.ZLim(1)*ones(length(y),1);
  yticks = [x y z ;x+ty y z];
  sendStr(6,sprintf('%f %f %f,\n',yticks'));

  % ZTICK
  tz = .05;
  z = obj.ZTick';
  x = obj.XLim(1)*ones(length(z),1);
  y = obj.YLim(2)*ones(length(z),1);
  zticks = [x y z;x y+tz z];
  sendStr(6,sprintf('%f %f %f,\n',zticks'));

% come clean this function up TODO
function axesTickCoordIndex(obj)
  n = length(obj.XTick);
  from = 0:n-1;
  to = from + n;
  index = [from;to];
  sendStr(6,sprintf('%d %d -1\n',index));

  currindex = 2*n;

  n = length(obj.YTick);
  from = currindex:currindex+n-1;
  to = from + n;
  index = [from; to];
  sendStr(6,sprintf('%d %d -1\n',index));

  currindex = currindex + 2*n;

  n = length(obj.ZTick);
  from = currindex:currindex+n-1;
  to = from + n;
  index = [from; to];
  sendStr(6,sprintf('%d %d -1\n',index));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%  Support Functions  %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outputAxesCube(obj)
  BeginShape('IndexedLineSet');
  sendStr(4,'coord Coordinate {\n');
  sendStr(5,'point [\n');
  cubepts = [0 0 0;0 0 1;0 1 0;0 1 1;1 0 0;1 0 1;1 1 0;1 1 1];
  cubepts(:,1) = cubepts(:,1).*diff(obj.XLim) + obj.XLim(1);
  cubepts(:,2) = cubepts(:,2).*diff(obj.YLim) + obj.YLim(1);
  cubepts(:,3) = cubepts(:,3).*diff(obj.ZLim) + obj.ZLim(1);
  sendStr(6,sprintf('%f %f %f,\n',cubepts'));
  sendStr(5,']\n');
  sendStr(4,'}\n');
  sendStr(4,'coordIndex [\n');
  sendStr(5,'0,1,3,2,-1\n');
  sendStr(5,'4,6,7,5,-1\n');
  sendStr(5,'0,2,6,4,-1\n');
  sendStr(5,'1,5,7,3,-1\n');
  sendStr(5,'6,2,3,7,-1\n');
  sendStr(5,'0,4,5,1,-1\n');
  sendStr(4,']\n');
  sendStr(4,sprintf('color Color {color [%f %f %f]}\n',obj.XColor));
  sendStr(4,'colorPerVertex FALSE\n');
  sendStr(3,'}\n');
  sendStr(2,'}\n');

function outputAxesTickLabels(obj)
  off = .1;
  for i=1:length(obj.XTick)
     tobj.String = num2str(obj.XTick(i));
     tobj.Position = [obj.XTick(i) obj.YLim(1)-off*diff(obj.YLim) obj.ZLim(1)];
     HandleText(tobj);
  end
  for i=1:length(obj.YTick)
     tobj.String = num2str(obj.YTick(i));
     tobj.Position = [obj.XLim(1)-off*diff(obj.XLim) obj.YTick(i) obj.ZLim(1)];
     HandleText(tobj);
  end
  for i=1:length(obj.ZTick)
     tobj.String = num2str(obj.ZTick(i));
     tobj.Position = [obj.XLim(1)-off*diff(obj.XLim) obj.YLim(2) obj.ZTick(i)];
     HandleText(tobj);
  end

function outputAxesTicks(obj)
  BeginShape('IndexedLineSet');
  coord(obj,'axesTickCoord');
  coordIndex(obj,'axesTickCoordIndex');
  EndShape;

% later this function will make a def and use decision  pax
function outputColormap(cmap)
  sendStr(6,sprintf('%f %f %f,\n',cmap'));
  sendStr(6,sprintf('%f %f %f', [1 1 1])); %because of import 3d

function rdata = colorMapping(data, clim, colormap_length, mapping_type)
  switch mapping_type
  case 'direct'
     rdata = floor(data);
     lower = find(rdata < 1);
     rdata(lower) = 1; %#ok
     higher = find(rdata > colormap_length);
     rdata(higher) = colormap_length; %#ok
  case 'scaled'
     h = find(data < clim(1)); data(h) = clim(1); %#ok
     h = find(data > clim(2)); data(h) = clim(2); %#ok
     rdata = floor(((data - clim(1))/(clim(2) - clim(1)))*(colormap_length - 1));
     %rdata = floor(data * colormap_length);
  otherwise
     error(id('InvalidMappingType'),'Unknown mapping type in function colorMapping');
  end

% Send a string to the VRLM file
function sendStr(indent,str)
global VRML_OUTPUT_FILE;
tabs = '                    ';
fprintf(VRML_OUTPUT_FILE,tabs(1:indent));
fprintf(VRML_OUTPUT_FILE,str);

function [qres] = quatMul(q1, q2)
  qres = [cross(q1(1:3), q2(1:3)), q1(4)*q2(4) - dot(q1(1:3), q2(1:3))];
  qres(1:3) = qres(1:3) + q1(1:3) * q2(4) ...
                  + q2(1:3) * q1(4);

function [rotAxis, rotAngle] = toAxisAngle(q)
  halfAngle = acos(q(4));
  sinHalfAngle = sin(halfAngle);
  rotAngle = halfAngle * 2.0;
  if (abs(sinHalfAngle) < 1e-8)
    rotAxis = [1, 0, 0];
  else
    rotAxis = q(1:3) / sinHalfAngle;
  end

function [q] = computeQuatFromAxisCosAngle(axis, cosAngle)
  if (cosAngle > 1.0), cosAngle = 1.0; end
  if (cosAngle < -1.0), cosAngle = -1.0; end
  angle = acos(cosAngle);
  sinHalfAngle = sin(angle / 2);
  cosHalfAngle = cos(angle / 2);
  q = [axis * sinHalfAngle, cosHalfAngle];

function [o] = computeOrientationFromCamera(cameraPos, cameraAt, cameraUp)
  cameraUp = cameraUp ./ norm(cameraUp);
  n =  cameraAt - cameraPos;
  n = n ./ norm(n);

  v = cameraUp - dot(cameraUp, n) * n;
  v = v ./ norm(v);
  normAxis = [n(2) -n(1) 0];

  if (dot(normAxis, normAxis) < 1e-8)
    if (n(3) > 0.0)
      normQuat = [0, 1, 0, 1];
    else
      normQuat = [0, 0, 0, 1];
    end
  else
    normAxis = normAxis ./ norm(normAxis);
    normQuat = computeQuatFromAxisCosAngle(normAxis, -n(3));
  end
  invNormQuat = [-normQuat(1:3), normQuat(4)];
  yQuat = [0, 1, 0, 0];
  newYQuat = quatMul(normQuat, yQuat);
  newYQuat = quatMul(newYQuat, invNormQuat);
  newY = newYQuat(1:3);

  tempV = cross(newY, v);
  if (dot(tempV, tempV) < 1e-8)
    tempV = [0, -v(3), v(2)];
    if dot(tempV, tempV) < 1e-8
      tempV = [v(3), 0.0, -v(1)];
    end
  end
  tempV = tempV ./ norm(tempV);

  rotYQuat = computeQuatFromAxisCosAngle(tempV, dot(newY, v));
  rotQuat = quatMul(rotYQuat, normQuat);
  [rotAxis, rotAngle] = toAxisAngle(rotQuat);

  o = [rotAxis, rotAngle];

% return message id for vrml
function msgID = id(errID)

msgID = ['MATLAB:vrml:' errID];

