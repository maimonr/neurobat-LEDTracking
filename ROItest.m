function  ROItest(videoFolders) 

folders = dir(videoFolders);
folders = folders(3:end); % get rid of 'wildcard' entries, idk what they are fuck'em 

ROIIdx(1,:) = [35 810 300 1420]; 
fisheyeModel = load('fisheye_model.mat'); 
cameraParams = fisheyeModel.cameraParams; 
VidNum = 5 ; % just arbitrary we choose one to represent the day

for i = 1:size(folders,1)
videoDir = [folders(i).folder,'\',folders(i).name]; 
video_fNames = dir(fullfile(videoDir,'*.mp4'));
v = VideoReader(fullfile(video_fNames(VidNum).folder,video_fNames(VidNum).name));
v.CurrentTime = 10; % just arbitrary 
  f = readFrame(v); 
  fFish = undistortFisheyeImage(f, cameraParams.Intrinsics);
figure; 
  imshowpair(fFish,fFish(35:810,300:1420,:),'montage');
  title(videoDir(44:end))
  
end
end
