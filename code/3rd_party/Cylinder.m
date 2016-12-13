 function [CylinderHandle ] = Cylinder(X1,X2,r,n,cyl_color,closed,lines)
%
% This function constructs a cylinder connecting two center points
%
% Usage :
% [Cylinder EndPlate1 EndPlate2] = Cylinder(X1+20,X2,r,n,'r',closed,lines)
%
% Cylinder-------Handle of the cylinder
% EndPlate1------Handle of the Starting End plate
% EndPlate2------Handle of the Ending End plate
% X1 and X2 are the 3x1 vectors of the two points
% r is the radius of the cylinder
% n is the no. of elements on the cylinder circumference (more--> refined)
% cyl_color is the color definition like 'r','b',[0.52 0.52 0.52]
% closed=1 for closed cylinder or 0 for hollow open cylinder
% lines=1 for displaying the line segments on the cylinder 0 for only
% surface
%
% Typical Inputs
% X1=[10 10 10];
% X2=[35 20 40];
% r=1;
% n=20;
% cyl_color='b';
% closed=1;
%
% NOTE: There is a MATLAB function "cylinder" to revolve a curve about an
% axis. This "Cylinder" provides more customization like direction and etc
if ~exist('cyl_color','var')
    cyl_color = 'r';
end
if ~exist('closed','var')
    closed = 1;
end
if ~exist('lines','var')
    lines = 0;
end



% Calculating the length of the cylinder
length_cyl=norm(X2-X1);

% Creating a circle in the YZ plane
t=linspace(0,2*pi,n)';
x2=r*cos(t);
x3=r*sin(t);

% Creating the points in the X-Direction
x1=[0 length_cyl];

% Creating (Extruding) the cylinder points in the X-Directions
xx1=repmat(x1,length(x2),1);
xx2=repmat(x2,1,2);
xx3=repmat(x3,1,2);


% Plotting the cylinder along the X-Direction with required length starting
% from Origin
TRI = delaunay(xx1(:),[t;t]);
if closed==1
    % add triangles for plates
    TRI_Plate = delaunay(xx2(:,1),xx3(:,1));
    TRI = [TRI ; TRI_Plate ; TRI_Plate+n];
end
CylinderHandle = trisurf(TRI, xx1(:),xx2(:),xx3(:),'facecolor',cyl_color);

% Defining Unit vector along the X-direction
unit_Vx=[1 0 0];

% Calulating the angle between the x direction and the required direction
% of cylinder through dot product
angle_X1X2=acos( dot( unit_Vx,(X2-X1) )/( norm(unit_Vx)*norm(X2-X1)) )*180/pi;

% Finding the axis of rotation (single rotation) to roate the cylinder in
% X-direction to the required arbitrary direction through cross product
axis_rot=cross([1 0 0],(X2-X1) );

% Rotating the plotted cylinder and the end plate circles to the required
% angles
if angle_X1X2~=0 && angle_X1X2~=180  % Rotation is not needed if required direction is along X
    rotate(CylinderHandle,axis_rot,angle_X1X2,[0 0 0])
end
if angle_X1X2==180
   X1 = X2;
end

% Till now cylinder has only been aligned with the required direction, but
% position starts from the origin. so it will now be shifted to the right
% position

V = get(CylinderHandle,'Vertices');
V = bsxfun(@plus,V,X1);
set(CylinderHandle,'Vertices',V)


% If lines are not needed making it disapear
if lines==0
    set(CylinderHandle,'EdgeColor','none')
end