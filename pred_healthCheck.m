
function  pred_healthCheck(predDir) 
  
files = dir(predDir);
files = files(3:end); % get rid of 'wildcard' entries, idk what they are fuck'em 

for FileNum = 1:size(files,1)
    currentFile = files(FileNum).name;
    load([predDir,'\',currentFile]);



% prepare some things:

load('color_pred_model_august'); 
color_names = color_pred_model_august.ClassificationSVM.ClassNames;    % should be this: {'az','ch','gr','or','rd','re','sp','vi'}' 
numberOfcolors = size(color_names,1); 
pred_more_then_once = zeros(1,8);  
Numofblobs_all =[];
Lab_all = [];

% (1) Remove times when a color is predicted more then once by taking only the max posterior predcition blob. 
% and also count up the number of blobs 
for MovieNum = 2:size(centroidLocs,2) 
    for frame_k = 1:size(centroidLocs{1,MovieNum},2)  
    Numofblobs{frame_k} = size(cell2mat(centroidLocs{1,MovieNum}(frame_k)),1); 
        for color_k = 1:numberOfcolors 
        current_color_idx = strcmp(predColors{MovieNum}{frame_k},color_names{color_k}); 
            if sum(current_color_idx) > 1 
            pred_class_idx = strcmp(color_names,color_names(color_k,:)); 
            current_pred_posteriors = predPosterior{MovieNum}{frame_k}(current_color_idx,pred_class_idx);  
                if length(unique(current_pred_posteriors)) == 1 
                pred_centroids(frame_k,color_k,:) = NaN; 
                    continue
                else % This catches all times when we have more then one prediction of a specifc color, and usues max posterior choose one. 
                [~,pred_posterior_idx] = max(current_pred_posteriors);
                current_color_idx = find(current_color_idx);
                current_color_idx = current_color_idx(pred_posterior_idx);
                pred_more_then_once(color_k) = pred_more_then_once(color_k)+1;
                end
         elseif sum(current_color_idx) == 0
            pred_centroids(frame_k,color_k,:) = NaN;
                continue
         end
        pred_centroids(frame_k,color_k,:) = centroidLocs{MovieNum}{frame_k}(current_color_idx,:); 
        end
    end
    Day_prediction(MovieNum) = {pred_centroids}; 
    Numofblobs_all = cat(2,Numofblobs_all,Numofblobs); 
end 
Numofblobs_all = cell2mat(Numofblobs_all); 

% (2) Here we convert La*b* blob cells to one long matrix, and downsample to plot  

Lab = cat(2,predLab{:}); % puts all the cells in predLab to one dim
Lab = Lab(~cellfun('isempty',Lab)); % get rid of the empty cells so we can combine it to a matrix
Lab = cat(1,Lab{:}); % combine it to a matrix
%we want to downsmaple, but first randomize entries (so we don't undersample a specific color)
Lab_RIndex = randperm(size(Lab,1))'; 
Lab_RIndex5 = downsample(Lab_RIndex,5); 
tic
for i= 1:size(Lab_RIndex5,1)
    LabRand(i,:)=Lab(Lab_RIndex5(i),:);  
end 
toc 



% (3)number of predicted frames per movie
for MovieNum = 2:size(Day_prediction,2)
predicted = cell2mat(Day_prediction(MovieNum));
for color_index = 1:numberOfcolors
NumPredFrames(MovieNum,color_index) = sum(~isnan(predicted(:,color_index,1)));
end 
end 


 
%% Ploting the Plots as it were...
rgb_colors = {0 0.5 1;0.5 1 0;0 1 0;1 0.5 0;1 0 0;1 0 0.5;0 1 0.5;0.5 0 1}; % this makes sense for AgustModel. it might not if we make another...
 
figure(FileNum); 
set(gcf,'Color','white','Position',[80 80 800 550]);
subplot(3,3,1:3)
scatter(LabRand(:,1),LabRand(:,2),'.'); hold on;
scatter(color_pred_model_august.ClassificationSVM.X.a,color_pred_model_august.ClassificationSVM.X.b,'.')    
legend('prediction data','Model data','Location','southwest'); 

for i=1:numberOfcolors
subplot(3,3,4:6)
plot(NumPredFrames(:,i),'Color',cell2mat(rgb_colors(i,:)),'LineWidth',2); 
ylim([0 6500]); xlim([2,size(Day_prediction,2)]);
hold on;
end
title('# of frames that each color was predicted'); ylabel('# detected Frames'); xlabel('# of 5min movie'); legend(color_names,'Location','southwest','NumColumns',2);  

subplot(3,3,7:8)
plot(Numofblobs_all); title('Num of blobs per frame'); 
subplot(3,3,9)
histogram(Numofblobs_all); title('distribution of blobs/frame')
suptitle(['Prediction Health Check',currentFile]); 


saveas(gcf,['HC_',currentFile,'.png']) 
end 
end