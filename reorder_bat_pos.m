function reordered_bat_pos = reorder_bat_pos(batPos,T,expDate,sessionType,all_bat_nums,colorStrs)

bat_idx = contains(T.Properties.VariableNames,'Bat_');
color_idx = contains(T.Properties.VariableNames,'Color_');

nBats = length(all_bat_nums);
nSample = size(batPos,1);
reordered_bat_pos = nan(nSample,2,nBats);

T_exp = T(T.Date == expDate & strcmp(T.Session,sessionType),:);
bat_color_table = table(T_exp{1,bat_idx}',T_exp{1,color_idx}','VariableNames',{'batNum','color'});

for color_k = 1:length(colorStrs)
    color_bat_num = bat_color_table.batNum(contains(bat_color_table.color,colorStrs{color_k}));
    current_bat_idx = all_bat_nums == color_bat_num;
    reordered_bat_pos(:,:,current_bat_idx) = batPos(:,:,color_k);
end


end