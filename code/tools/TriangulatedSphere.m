function shape = TriangulatedSphere(n)

[X,Y,Z] = sphere(n);

[az,el] = cart2sph(X,Y,Z);
az(1,:)   = az(2,:);
az(end,:) = az(2,:);
az(:,1)   = -pi;

TRI = delaunay(az(:),el(:));

shape.X = X;
shape.Y = Y;
shape.Z = Z;
shape.TRI = TRI;

%%
return
%%
figure
[X,Y,Z] = sphere;
h = surf(X,Y,Z)  % sphere centered at origin
hold on
h = trisurf(TRI, X,Y,Z)
daspect([1 1 1])

%%
figure
trimesh(TRI, az,el)

