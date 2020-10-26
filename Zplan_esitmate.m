function  Zplan_esitmate(DataDir,SaveDir)

ROIIDX =[600,895,1,1040]; % ROI lims for social side cage;  
maxArea = 200; 
lightsTh = exp(16.5);

MovieFolders = dir(DataDir);
MovieFolders = MovieFolders(3:end); 

for folderNum = 1:size(MovieFolders,1)
folderName = [MovieFolders(folderNum).folder,'\',MovieFolders(folderNum).name]; 

MovieFiles = dir(folderName);
MovieFiles = MovieFiles(3:end); 

for fileNum = 1:size(MovieFiles,1) 
fileName = [MovieFiles(fileNum).folder,'\',MovieFiles(fileNum).name]; 
v = VideoReader(fileName);

i = 1;
v.CurrentTime = 0;
while hasFrame(v) 
    if v.CurrentTime < 5
   f = readFrame(v);
   if sum(f,'all') < lightsTh
   bw = getFrameMask(f,'ROI',ROIIDX);
  [centros,prop] = findLEDcentroid(bw); 
  centroidLocs{i} = centros;
  Areas{i} = [prop.Area];
  Zbats(i)= sum([prop.Area]<maxArea); 
   i = i+1;
   else
   end
    else 
        break
    end
end 

Zresults(fileNum).centroidLocs = centroidLocs;
Zresults(fileNum).Areas = Areas; 
Zresults(fileNum).Zbats = Zbats;
end
saveName = [SaveDir,'\Zresults_',MovieFolders(folderNum).name]; 
save(saveName,'Zresults')  

end

end

