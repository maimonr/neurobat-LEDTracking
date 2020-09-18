function [session_bat_corr,session_bat_pos,used_bat_pairs] = get_bat_corr_dist_by_session(eData,all_bat_nums,bat_dist_info,bat_pair_corr_info)
excl_bat_nums = 11682;
pos_bat_idx = ~ismember(all_bat_nums,excl_bat_nums) & ismember(all_bat_nums,str2double(eData.batNums));
used_date_idx = cellfun(@(x) ~isempty(x) && x ~= datetime(2020,8,3),{bat_dist_info.expDate});
all_bat_pos = arrayfun(@(x) squeeze(nanmean(x.dist,1)),bat_dist_info(used_date_idx),'un',0);
all_bat_pos = cat(3,all_bat_pos{:});
all_bat_pos = all_bat_pos(pos_bat_idx,pos_bat_idx,:);

used_pos_bat_nums = all_bat_nums(pos_bat_idx);

expDates = [bat_dist_info(used_date_idx).expDate];
used_bat_pairs = cellfun(@str2double,bat_pair_corr_info.all_bat_pairs);
corr_bat_idx = ~any(ismember(used_bat_pairs,excl_bat_nums),2);
used_bat_pairs = used_bat_pairs(corr_bat_idx,:);
n_bat_pair = sum(corr_bat_idx);
nExp = length(expDates);
f_k = 3;
t_idx = 8:12;

[session_bat_corr,session_bat_pos] = deal(nan(n_bat_pair,nExp));


for exp_k = 1:nExp
    dateIdx = bat_pair_corr_info.expDates == expDates(exp_k);
    nCall(exp_k) = sum(dateIdx);
    session_bat_corr(:,exp_k) = squeeze(nanmean(bat_pair_corr_info.bat_pair_corr(dateIdx,corr_bat_idx,f_k,t_idx),[1 4]));
    for bat_pair_k = 1:n_bat_pair
        current_bat_pos_idx = zeros(1,2);
        for bat_k = 1:2
           current_bat_pos_idx(bat_k) = find(used_pos_bat_nums == used_bat_pairs(bat_pair_k,bat_k));
        end
        session_bat_pos(bat_pair_k,exp_k) = all_bat_pos(current_bat_pos_idx(1),current_bat_pos_idx(2),exp_k);
    end
end

end