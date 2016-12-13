function patchHandle = PlotShape(shape,cData)

%cla reset;
if exist('cData','var')
    patchH = trisurf(shape.TRIV, shape.X, shape.Y, shape.Z, cData);
else
    patchH = trisurf(shape.TRIV, shape.X, shape.Y, shape.Z);
end
axis image off;
shading flat
% shading interp 

if nargout > 0
    patchHandle = patchH;
end