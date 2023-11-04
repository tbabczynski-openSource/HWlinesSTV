function [labels] = labelsFromLines(linTab, linNums, img)
%LABELSFROMLINES Associate number to each pixel in image based on polylines

DD = cell(size(linTab));
imgLines = zeros(size(img),'uint8');
labels = zeros(size(img),'uint8');

if(isempty(linTab)) %sanity check
  return; 
end

for j=1:size(linTab,2) %polylines
	for i=1:size(linTab{j},1)-1 %points in polyline
		coef = polyfit([linTab{j}(i,1), linTab{j}(i+1,1)], [linTab{j}(i,2), linTab{j}(i+1,2)], 1);
		y = round(polyval(coef,linTab{j}(i,1):linTab{j}(i+1,1)));
    y(y<1) = 1; %sometimes y comes out one pixel behind the image due to rounding
    y(y>size(img,1))=size(img,1);
    if i==1
      DD{j}=[y; linTab{j}(i,1):linTab{j}(i+1,1)];
    else
      DD{j}=[DD{j}(1,1:end-1), y;...
        DD{j}(2,1:end-1), linTab{j}(i,1):linTab{j}(i+1,1)];
    end
	end
    imgLines(sub2ind(size(img),DD{j}(1,:),DD{j}(2,:)))=linNums(j);
end

regions = regionprops(img,'BoundingBox','Image');

for r=1:size(regions)
  low = flip(ceil(regions(r).BoundingBox(1:2)));
  high = low+flip(regions(r).BoundingBox(3:4))-1;
  bb = imgLines(low(1):high(1),low(2):high(2));
  bbpos = unique(bb(bb>0));
  if size(bbpos,1)==1 && size(bbpos,2)>1 %region in image has height=1 but two lines crosses
    bbpos = bbpos';
  end
  if isempty(bbpos) %no line crosses
    margin=0;
    while isempty(bbpos) && margin<size(img,1)
      margin = margin+10;
      bbM = imgLines(max(1,low(1)-margin):min(size(img,1),high(1)+margin),...
        max(1,low(2)-margin):min(size(img,2),high(2)+margin));
      bbpos = unique(bbM(bbM>0));
    end
    if isempty(bbpos); continue; %Ugly workaround! But if not found...
    elseif size(bbpos,1)==1
      labels(low(1):high(1),low(2):high(2)) = ...
        labels(low(1):high(1),low(2):high(2)) + uint8(regions(r).Image)*bbpos;
    else
      bbi= zeros(size(bb),'uint8');
      [vy, vx]=find(bbM);
      vyM=vy-low(1)+max(1,low(1)-margin);
      vxM=vx-low(2)+max(1,low(2)-margin);
      [vyI,vxI]=find(regions(r).Image);
      vyI = vyI(:);
      vxI = vxI(:);
      [~,dI] = min(hypot(repmat(vyM,[1, size(vyI,1)])-repmat(vyI',[size(vyM,1), 1]),...
        repmat(vxM,[1, size(vxI,1)])-repmat(vxI',[size(vxM,1),1])));
      bbi(sub2ind(size(bbi),vyI,vxI)) = bbM(sub2ind(size(bbM),vy(dI),vx(dI)));
      
      labels(low(1):high(1),low(2):high(2)) = ...
        labels(low(1):high(1),low(2):high(2)) + bbi;
    end
  elseif size(bbpos,1)==1 %one line -> the whole region to this line
    labels(low(1):high(1),low(2):high(2)) = ...
      labels(low(1):high(1),low(2):high(2)) + uint8(regions(r).Image)*bbpos;
  else %more than one line
    bbi= zeros(size(bb),'uint8');
    [vy, vx]=find(bb);
    [vyI,vxI]=find(regions(r).Image);
    [~,dI] = min(hypot(repmat(vy,[1, size(vyI,1)])-repmat(vyI',[size(vy,1), 1]),...
      repmat(vx,[1, size(vxI,1)])-repmat(vxI',[size(vx,1),1])));
    bbi(sub2ind(size(bbi),vyI,vxI)) = bb(sub2ind(size(bbi),vy(dI),vx(dI)));

    labels(low(1):high(1),low(2):high(2)) = ...
      labels(low(1):high(1),low(2):high(2)) + bbi;
  end
end

end
