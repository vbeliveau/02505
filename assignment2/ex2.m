close all;
%% select 10 points
load('visiblehuman');
head_frozen=double(head_frozen);
head_fresh=double(head_fresh);
head_mri=double(head_mri);

% Each member selects points select
%cpselect(head,head_frozen);
%cpselect(head,head_fresh);
%cpselect(head,head_mri);

%save('control_points','head1','head2','head3','frozen','fresh','mri');

%% Compute transform between MRI and CT and corresponding FLE and FRE

load('control_points'); 
figure;
imagesc(head);
hold on;
plot(head1(:,1),head1(:,2),'r+','MarkerSize',20);
hold on;
plot(head2(:,1),head2(:,2),'gx','MarkerSize',20);
hold on;
plot(head3(:,1),head3(:,2),'y.','MarkerSize',20);

figure;
imagesc(head_frozen);
hold on;
plot(frozen(:,1),frozen(:,2),'r+','MarkerSize',10);

figure;
imagesc(head_fresh);
hold on;
plot(fresh(:,1),fresh(:,2),'r+','MarkerSize',10);

figure;
imagesc(head_mri);
hold on;
plot(mri(:,1),mri(:,2),'r+','MarkerSize',10);


% Compute FLE
N=10; J=3; D=2;
X=cat(3,head1,head2,head3);
u=mean(X,3);
var_FLE=sum(reshape((X-repmat(u,[1,1,J])).^2,1,N*J*D))/(2*N*J)

% Estimate parameters from MRI to frozen CT
x=mri;
xm=mean(x);
xc=bsxfun(@minus,x,xm);
y=frozen;
ym=mean(y);
yc=bsxfun(@minus,y,mean(y));
H=xc'*yc;
[U,D,V]=svd(H);
R=V*diag([1,det(V*U)])*U'
s=sum(diag(xc*R'*yc'))/sum(diag(xc*xc'))
t=ym'-s*R*xm'
yhat=(s*R*x'+repmat(t,1,size(x,1)))';
FRE_mri_ct=sum(reshape((yhat-y).^2,1,numel(y)))
s_mri_ct=s; R_mri_ct=R; t_mri_ct=t;

% Plot MRI control points on frozen CT
figure;
imagesc(head_frozen);
hold on;
plot(y(:,1),y(:,2),'mx','MarkerSize',10);
hold on;
plot(yhat(:,1),yhat(:,2),'g+','MarkerSize',10);

% Estimate parameters from frozen CT to MRI
x=frozen;
xm=mean(x);
xc=bsxfun(@minus,x,xm);
y=mri;
ym=mean(y);
yc=bsxfun(@minus,y,mean(y));
H=xc'*yc;
[U,D,V]=svd(H);
R=V*diag([1,det(V*U)])*U'
s=sum(diag(xc*R'*yc'))/sum(diag(xc*xc'))
t=ym'-s*R*xm'
yhat=(s*R*x'+repmat(t,1,size(x,1)))';
FRE_ct_mri=sum(reshape((yhat-y).^2,1,numel(y)))

%% Transform MR to CT using bilinear interpolation

% Plot CT frozen control points on MRI
figure;
imagesc(head_mri);
hold on;
plot(y(:,1),y(:,2),'mx','MarkerSize',10);
hold on;
plot(yhat(:,1),yhat(:,2),'g+','MarkerSize',10);

V=head_mri;
[X_mri,Y_mri]=meshgrid(0:(size(head_mri,1)-1),0:(size(head_mri,2)-1));
coords=s_mri_ct*R_mri_ct*[X_mri(:) Y_mri(:)]'+repmat(t_mri_ct,1,numel(X_mri));
X=reshape(coords(1,:),size(X_mri)); Y=reshape(coords(2,:),size(Y_mri));
[Xq,Yq]=meshgrid(0:(size(head_frozen,2)-1),0:(size(head_frozen,1)-1));
Vq=griddata(X,Y,V,Xq,Yq,'linear'); % interp2 doesn't work with non-uniform grid like X and Y here
fusionRGB=cat(3,head_frozen/256,Vq/256,zeros(size(Vq)));
figure; imshow(fusionRGB);

