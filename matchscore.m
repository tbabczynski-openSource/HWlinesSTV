function [o2o_cnt, M, N, bad] = matchScore(labImg, inputPath, outputPath)
  
  %% read labeled image and ground truth file
  
  Tru = getResultMat(inputPath,'.dat'); %ground truth
  Res = uint8(labImg);
  if(exist('outputPath','var') && ischar(outputPath))
    putResultMat(Res,outputPath,'.dat');
  end
  
  %% Calculate confusion matrix and match table
  
  acceptThreshold=0.945; %competition rules set it to 95% but this value makes that our function gives the same results as the competition checker
  ind = Res>0 | Tru>0;
  [c, order]=confusionmat(Res(ind),Tru(ind));
  c1=sum(c,1);
  c2=sum(c,2);
  %remove background data
  c(order==0,:)=[];
  c(:,order==0)=[];
  c1(order==0)=[];
  c2(order==0)=[];
  c1(sum(c,1)==0)=[];
  c2(sum(c,2)==0)=[];
  c(:,sum(c,1)==0)=[];
  c(sum(c,2)==0,:)=[];
    
  [M, N]=size(c);
  c_norm=c./(repmat(c1,[M, 1])+repmat(c2,[1, N])-c);
  c_norm=round(c_norm+0.00,3);
  match_count=(c_norm>=acceptThreshold);
  
%% one to one
  g_proj = sum(match_count,1);
  r_proj = sum(match_count,2);
  o2o = match_count==1 & repmat(g_proj,[M,1])==1 & repmat(r_proj,[1,N])==1;
  o2o_cnt = sum(o2o(:));
  if (o2o_cnt~=sum(match_count(:)))
    warning('o2o=%d, sum=%d',o2o_cnt, sum(match_count(:)))
  end
  
  bad = find(sum(o2o,2)==0)';
%% stats
  DR = o2o_cnt/N;
  RA = o2o_cnt/M;
  FM = 2*DR*RA/(DR+RA);
end




%% helper functions

function M = getResultMat(name, suf)
  % GETRESULTMAT gets matrix of ground truth or result matrix from .dat file
  
  ImgInfo = imfinfo(name);
  fi = fopen([name, suf]);
  M = fread(fi,[ImgInfo.Width, ImgInfo.Height],'uint32=>uint8');
  M = M';
  fclose(fi);
end

function putResultMat(M, name, suf)
  % PUTRESULTMAT puts matrix of result to .dat file
%   ImgInfo = imfinfo(name);
  fo = fopen([name, suf],'w');
  M = M';
  fwrite(fo,M,'integer*4');
  fclose(fo);
end