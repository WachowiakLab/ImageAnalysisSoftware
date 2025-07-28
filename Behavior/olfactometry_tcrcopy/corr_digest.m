function final=corr_digest(varargin)

corrr=varargin{1};
disp(corrr)

strong_all_tot=[];
weak_all_tot=[];
strong_first_tot=[];
weak_first_tot=[];
for i=1:length(corrr)
    strong_all=[];
    if ~isempty(corrr(i).strong)
        st_a=[corrr(i).strong.all];
        strong_all(:,1)=[st_a.corr];
        strong_all(:,2)=[st_a.p_val];
    end
    weak_all=[];
    if ~isempty(corrr(i).weak)
        wk_a=[corrr(i).weak.all];
        weak_all(:,1)=[wk_a.corr];
        weak_all(:,2)=[wk_a.p_val];
    end
    strong_first=[];
    if ~isempty(corrr(i).strong)
        st_f=[corrr(i).strong.first];
        strong_first(:,1)=[st_f.corr];
        strong_first(:,2)=[st_f.p_val];
    end
    weak_first=[];
    if ~isempty(corrr(i).weak)
        wk_f=[corrr(i).weak.first];
        weak_first(:,1)=[wk_f.corr];
        weak_first(:,2)=[wk_f.p_val];
    end
        
    strong_all_tot=[strong_all_tot;strong_all];
    weak_all_tot=[weak_all_tot;weak_all];
    strong_first_tot=[strong_first_tot;strong_first];
    weak_first_tot=[weak_first_tot;weak_first];
    
end
strong_all_corr=strong_all_tot(:,1);
weak_all_corr=weak_all_tot(:,1);
strong_first_corr=strong_first_tot(:,1);
weak_first_corr=weak_first_tot(:,1);

strong_all_corr(isnan(strong_all_corr))=[];
weak_all_corr(isnan(weak_all_corr))=[];
strong_first_corr(isnan(strong_first_corr))=[];
weak_first_corr(isnan(weak_first_corr))=[];

strong_all_mean=mean(strong_all_corr);
weak_all_mean=mean(weak_all_corr);
strong_first_mean=mean(strong_first_corr);
weak_first_mean=mean(weak_first_corr);

strong_all_std=std(strong_all_corr);
weak_all_std=std(weak_all_corr);
strong_first_std=std(strong_first_corr);
weak_first_std=std(weak_first_corr);

strong_all_sem=strong_all_std./sqrt(length(strong_all_corr));
weak_all_sem=weak_all_std./sqrt(length(weak_all_corr));
strong_first_sem=strong_first_std./sqrt(length(strong_first_corr));
weak_first_sem=weak_first_std./sqrt(length(weak_first_corr));

strong_all_p=strong_all_tot(strong_all_tot(:,2)<=0.05,1);
weak_all_p=weak_all_tot(weak_all_tot(:,2)<=0.05,1);
strong_first_p=strong_first_tot(strong_first_tot(:,2)<=0.05,1);
weak_first_p=weak_first_tot(weak_first_tot(:,2)<=0.05,1);


ratio_strong_all=length(strong_all_p)./length(strong_all_corr);
ratio_weak_all=length(weak_all_p)./length(weak_all_corr);
ratio_strong_first=length(strong_first_p)./length(strong_first_corr);
ratio_weak_first=length(weak_first_p)./length(weak_first_corr);


final_strong_all=[strong_all_mean, strong_all_std, strong_all_sem, ratio_strong_all];
final_weak_all=[weak_all_mean, weak_all_std, weak_all_sem, ratio_weak_all];
final_strong_first=[strong_first_mean, strong_first_std, strong_first_sem, ratio_strong_first];
final_weak_first=[weak_first_mean, weak_first_std, weak_first_sem, ratio_weak_first];

final(1)={final_strong_all};
final(2)={final_weak_all};
final(3)={final_strong_first};
final(4)={final_weak_first};



end







% strong_all_p(isnan(strong_all_p))=[];
% weak_all_p(isnan(weak_all_p))=[];
% strong_first_p(isnan(strong_first_p))=[];
% weak_first_p(isnan(weak_first_p))=[];
% 
% strong_all_p_mean=mean(strong_all_p);
% weak_all_p_mean=mean(weak_all_p);
% strong_first_p_mean=mean(strong_first_p);
% weak_first_p_mean=mean(weak_first_p);
% 
% strong_all_p_std=std(strong_all_p);
% weak_all_p_std=std(weak_all_p);
% strong_first_p_std=std(strong_first_p);
% weak_first_p_std=std(weak_first_p);

% 
% final_strong_all=[strong_all_mean, strong_all_std, strong_all_p_mean, strong_all_p_std, ratio_strong_all];
% final_weak_all=[weak_all_mean, weak_all_std, weak_all_p_mean, weak_all_p_std, ratio_weak_all];
% final_strong_first=[strong_first_mean, strong_first_std, strong_first_p_mean, strong_first_p_std, ratio_strong_first];
% final_weak_first=[weak_first_mean, weak_first_std, weak_first_p_mean, weak_first_p_std, ratio_weak_first];
