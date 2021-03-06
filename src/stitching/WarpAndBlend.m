function Out = WarpAndBlend(H,ImL,ImR)
    T = maketform('projective',H');
    % do homography transformation, find xmin, xmax, ymin, ymax
    [~,XData,YData]=imtransform(ImL,T,'FillValues',zeros(size(ImL,3),1));

    % find out output image size
    XData=[floor(XData(1)) ceil(XData(2))];
    YData=[floor(YData(1)) ceil(YData(2))];
    nX = [min(0,XData(1)) max(size(ImR,2),XData(2))];
    nY = [min(0,YData(1)) max(size(ImR,1),YData(2))];

    [ImLH]=imtransform(ImL,T,'XData',nX,'YData',nY,'FillValues',zeros(size(ImL,3),1));
    [ImRH]=imtransform(ImR,maketform('affine',eye(3)),'XData',nX,'YData',nY,'FillValues',zeros(size(ImL,3),1));

    % do the same for a mask
    Mask1=ones(size(ImL,1),size(ImL,2));
    Mask2=ones(size(ImR,1),size(ImR,2));

    Mask1=imtransform(Mask1,T,'XData',nX,'YData',nY,'FillValues',0)>0;
    Mask2=imtransform(Mask2,maketform('affine',eye(3)),'XData',nX,'YData',nY,'FillValues',0)>0;
    Maskavg = Mask1 & Mask2;
    Out = uint8(zeros(size(ImLH)));

    dist1 = zeros(size(ImL,1),size(ImL,2));%dist1(round(size(ImL,1)*0.5),round(size(ImL,2)*0.5)) = 1;
    dist1(1,:) = 1;dist1(end,:) = 1;dist1(:,1) = 1;dist1(:,end) = 1;
    dist1 = bwdist(dist1,'euclidean');%maxdist = max(dist1(:));dist1 = (maxdist+1) - dist1;
    
    dist2 = zeros(size(ImR,1),size(ImR,2));%dist2(round(size(ImR,1)*0.5),round(size(ImR,2)*0.5)) = 1;
    dist2(1,:) = 1;dist2(end,:) = 1;dist2(:,1) = 1;dist2(:,end) = 1;
    dist2 = bwdist(dist2,'euclidean');%maxdist = max(dist2(:));dist2 = (maxdist+1) - dist2;

    dist1t=imtransform(dist1,T,'XData',nX,'YData',nY,'FillValues',0);
    dist2t=imtransform(dist2,maketform('affine',eye(3)),'XData',nX,'YData',nY,'FillValues',0);

%     blender = vision.AlphaBlender('Operation', 'Binary mask', ...
%         'MaskSource', 'Input port');
% 
%     Out = step(blender, ImLH, ImRH, Mask2);

    if size(ImL,3) == 1
        Out = combine(ImLH, ImRH, dist1t, dist2t);
    else
        Out(:,:,1) = combine(ImLH(:,:,1), ImRH(:,:,1), dist1t, dist2t);
        Out(:,:,2) = combine(ImLH(:,:,2), ImRH(:,:,2), dist1t, dist2t);
        Out(:,:,3) = combine(ImLH(:,:,3), ImRH(:,:,3), dist1t, dist2t);
    end
end

function imblend = poissonBlend(source,target,mask)
    m = size(source,1);n = size(source,2);
    N = m*n;
    A = spdiags([-4.*ones(N,1) ones(N,1) ones(N,1) ones(N,1) ones(N,1)],[0,1,-1,m,-m],N,N);
    ii = m:m:N-m;
    jj = ii+1;
    A((ii-1)*N+jj) = 0;
    ii = m:m:N-m;
    A((ii.*N+ii)) = 0;
    % gradient of source
    ds = A * source(:);
    % gradient of target
    dt = A * target(:);
    
end

function im12 = combine(im1, im2, dist1,dist2)
    weight1 = dist1./(max(dist1(:)));
    weight2 = dist2./(max(dist2(:)));
    weights = weight1 + weight2;
    
    im12 = weight1.*im2double(im1) + weight2.*im2double(im2);
    im12 = im12 ./ weights;

    im12 = uint8(255/(max(im12(:))-min(im12(:))).*(im12-min(im12(:))));
end