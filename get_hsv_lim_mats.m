function hsv_lims_mat_table = get_hsv_lim_mats(ImSize,hsvTable)

% function that takes the output of get_hsv_lims and converts those color
% ranges into matrices the size of the image to be filtered. by
% pre-calculating these matrices, we save time filtering each individual
% image

nColor = size(hsvTable,2);
[channelsMin_mat,channelsMax_mat] = deal(cell(1,nColor));

for color_k = 1:nColor
    hsvLims = hsvTable{:,color_k};
    % Define thresholds for channel 1 based on histogram settings
    channel1Min = hsvLims(1,1);
    channel1Max = hsvLims(1,2);
    % Define thresholds for channel 2 based on histogram settings
    channel2Min = hsvLims(2,1);
    channel2Max = hsvLims(2,2);
    % Define thresholds for channel 3 based on histogram settings
    channel3Min = hsvLims(3,1);
    channel3Max = hsvLims(3,2);
    channelsMin = [channel1Min channel2Min channel3Min];
    channelsMax = [channel1Max channel2Max channel3Max];
    channelsMin_mat{color_k} = permute(repmat(channelsMin',1,ImSize(1),ImSize(2)),[2 3 1]);
    channelsMax_mat{color_k} = permute(repmat(channelsMax',1,ImSize(1),ImSize(2)),[2 3 1]);
end

hsv_lims_mat_table = array2table(vertcat(channelsMin_mat,channelsMax_mat),'VariableNames',hsvTable.Properties.VariableNames,'RowNames',{'Min','Max'});

end