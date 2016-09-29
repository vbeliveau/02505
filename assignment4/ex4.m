%% Construct a set of 2D tensor B-spline basis functions

%image dimensions
m = [20 20];
% number of knots
p1 = 3; p2 = 3;

% knot sequence 1
k1 = linspace(1,m(1),p1); k1 = augknt(k1,2);

% knot sequence 2
k2 = linspace(1,m(2),p2); k2 = augknt(k2,2);

% Form B-spline matrix Q which contains basic functions
B1 = spmak(k1,eye(p1)); Q1 = fnval(B1,1:m(1))';
%
B2 = spmak(k2,eye(p2)); Q2 = fnval(B2,1:m(2))';

Q = kron(speye(2),kron(Q2,Q1));

% Set all elements of w1 to a values and elements of w2 to 0
w = [40*ones(9,1); zeros(9,1)];
[x1,x2] = meshgrid(1:m(1),1:m(2));
y = [x1(:); x2(:)] + Q*w;
y1 = reshape(y(1:end/2),size(x1,1),size(x1,2));
y2 = reshape(y(end/2+1:end),size(x1,1),size(x1,2));
plotgrid(y1,y2);

% Set all elements of w1 to a values and elements of w2 to 0
w = [zeros(9,1); 20*ones(9,1)];
[x1,x2] = meshgrid(1:m(1),1:m(2));
y = [x1(:); x2(:)] + Q*w;
y1 = reshape(y(1:end/2),size(x1,1),size(x1,2));
y2 = reshape(y(end/2+1:end),size(x1,1),size(x1,2));
plotgrid(y1,y2);

% Set all elements of w1 and w2 to 0 except for the 9th basis
w = [zeros(8,1); 4; ones(8,1); 15];
[x1,x2] = meshgrid(1:m(1),1:m(2));
y = [x1(:); x2(:)] + Q*w;
y1 = reshape(y(1:end/2),size(x1,1),size(x1,2));
y2 = reshape(y(end/2+1:end),size(x1,1),size(x1,2));
plotgrid(y1,y2);

%% Perform non-linear intensity-based registration with Gauss-Newton optimization

% Select 2 mid-axial images
load mri.mat
img1=double(squeeze(D(:,:,1,15)));
img2=double(squeeze(D(:,:,1,17)));
m=size(img1);

% Specify voxels coordinates
[x1,x2]=meshgrid(1:m(2),1:m(1));
min_x1=min(x1(:)); max_x1=max(x1(:));
min_x2=min(x2(:)); max_x2=max(x2(:));

% Set basis functions
m = size(img1);
p1 = 7; p2 = 7;
k1 = linspace(1,m(1),p1); k1 = augknt(k1,2);
k2 = linspace(1,m(2),p2); k2 = augknt(k2,2);
B1 = spmak(k1,eye(p1)); Q1 = fnval(B1,1:m(1))';
B2 = spmak(k2,eye(p2)); Q2 = fnval(B2,1:m(2))';
Q = kron(speye(2),kron(Q2,Q1));

% Set regularizer matrix
G=eye(size(Q,2));

% 1. choose initial value w
w=rand(size(Q,2),1);

alpha=0.1;
% 2. while not STOP
thr=1e-4;
maxiter=100;
I=nan(1,maxiter);
iter=1;

nupdate=5;
h=figure;
subplot(2,3,1); imagesc(img1); axis off;
subplot(2,3,4); imagesc(img2); axis off;

while true

    % 3. calculate transformation y=x+Qw
    y=[x1(:); x2(:)] + Q*w;

    % 4. calculate transformed image T(y) and its spatial derivatives ∇T(y)
    y1 = reshape(y(1:end/2),m);
    y2 = reshape(y(end/2+1:end),m);
    y1(y1<min_x1)=min_x1(1); y1(y1>max_x1)=max_x1(1);
    y2(y2<min_x2)=min_x2(1); y2(y2>max_x2)=max_x2(1);

    ind = sub2ind(m,round(y2(:)),round(y1(:))); % Assume img1 and img2 are the same size
    Ty=img2(ind); Ty=reshape(Ty,m);
    img_diff=img1-Ty;
    [dxTy,dyTy]=gradient(Ty);
    dTy=[dxTy(:); dyTy(:)];
    
    % 5. solve for update ∆w using Eq. (2.34)
    A=repmat(dTy,1,size(Q,2)).*Q;    
    dw=pinv(A'*A+alpha*(G'*G))*(A'*repmat(img_diff(:),2,1)-alpha*(G'*G)*w);
    
    % 6. update w := w + ∆w
    
    % If objective function increases, do half-step
    sum_img_diff=sum(img_diff(:));
    if iter>1 && I(iter-1)<0.5*(sum_img_diff+alpha*norm(G*(w+dw))^2); 
        w=w+dw/2;
    else
        w=w+dw;
    end
    I(iter)=0.5*(sum_img_diff+alpha*norm(G*w)^2);
    
    % 7. end while
    I(iter)
    
    if mod(iter,nupdate)==1
        figure(h);
        subplot(2,3,2); imagesc(Ty); axis off;
        subplot(2,3,5); imagesc(img_diff); axis off;
        ha=subplot(1,3,3); cla; plotgrid(y1,y2,'prune',7);
        pause(0.1);
    end
    if iter>1 && abs(I(iter-1)-I(iter))<thr && iter<maxiter
            break;
    end
    iter=iter+1;
end
if iter==maxiter, error('Did not converge'); end