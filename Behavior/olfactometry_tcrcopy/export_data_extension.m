function export_data_extension(interface)

interface.add(export_view(interface.getBlankInitializer()))


%initializer for default_view
    function init = export_view(init)
        init.uid = 'export_view';
        init.name = 'Export data';
        init.group = 'Analysis editing tools';
        init.onRightClick = @rightClick;
        init.onCheck = @loadEditor;
        init.onUncheck = @unloadEditor;
        toolboxVisible = true;
        
        function loadEditor
            toolboxVisible = true;
            showToolbox
            interface.register_event_listener('mainaxes_click', @fcn_plot_click);
        end
        function unloadEditor
            if toolboxVisible
                hideToolbox
            end
            interface.unregister_event_listener('mainaxes_click', @fcn_plot_click);
        end
        
        function hideToolbox(varargin)
            interface.unregister_event_listener('before_unload_trial',@clear_current_trial_details)
            interface.unregister_event_listener('after_load_trial',@refresh_current_trial_details)
            toolboxVisible = false;
            delete(h.fig);
        end
        
        function rightClick(menu)
            set(menu,'Visible','on')
            if toolboxVisible
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Show toolbox', 'Checked', checked, 'Callback', @toggle_toolbox_visible)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function toggle_toolbox_visible(varargin)
                toolboxVisible = ~toolboxVisible;
                if toolboxVisible
                    showToolbox
                else
                    hideToolbox
                end
            end

            function show_about(varargin)
                msgbox({'This is just a small tool to export a whole session or one trial to either a file or workspace.','','TC','30 December 2010'}, init.name)
            end
        end
    
        h=[]; trial_selection=[]; roi_selection=[]; use_thresh=[]; thresh_chkbx=[];
        make_fig=[]; use_makefig=[]; br_frq=[]; use_epoch=[]; choose_odor=[]; 
        exp_2_wrkspce=[]; use_exp_2_wrkspce=[]; exp_2_file=[]; use_exp_2_file=[];

        function showToolbox
             o=interface.getOlfact();tri=[o.trials];deta=[tri.detail];od_list=unique({deta.odorant_name});
            h.fig = figure('Name','Export data','Units','pixels',...
                'Position',[400 400 570 180],...
                'MenuBar', 'none', 'DockControls', 'off', 'HandleVisibility','off','NumberTitle', 'off', ...
                'CloseRequestFcn',@hideToolbox,'Resize','off','Color', get(0,'DefaultUicontrolBackgroundColor'));
            
            make_fig = uicontrol('Parent',h.fig,'Style','checkbox','String','Make figures','Units','pixels',...
                'Position',[205 110 200 20],'Min',0,'Max',1,'Callback',@make_fig_Callback);
            set(make_fig,'Value',get(make_fig,'Min'));
            use_makefig=get(make_fig,'Value');
            
            h.first_only = uicontrol('Parent',h.fig,'Style','checkbox','String','first sniff only','Units','pixels',...
                'Position',[205 90 200 20],'Value',0);
                        
            exp_2_file=uicontrol('Parent',h.fig,'style','checkbox','String','Export to file','Units','pixels',...
                'Position',[205 60 150 20],'Callback',@exp_2_file_Callback);
            set(exp_2_file,'Value',get(exp_2_file,'Min'));
            use_exp_2_file=get(exp_2_file,'Value');
            
            exp_2_wrkspce=uicontrol('Parent',h.fig,'style','checkbox','String','Export to workspace','Units','pixels',...
                'Position',[205 40 150 20],'Min',0,'Max',1,'Callback',@exp_2_wrkspce_Callback);
            set(exp_2_wrkspce,'Value',get(exp_2_wrkspce,'Min'));
            use_exp_2_wrkspce=get(exp_2_wrkspce,'Value');

            uicontrol('Parent',h.fig,'style','text','String','Select :', 'Units','pixels','Position',[2 87 65 15]);
            trial_selection = uicontrol('Parent',h.fig,'style','popupmenu','String',{'All trials','Selected trials','This trial'},...
                'Units','pixels','Position',[65 85 110 25],'BackgroundColor',[1 1 1]);
            uicontrol('Parent',h.fig,'style','text','string','ROIs :','units','pixels','position',[2 57 65 15]);
            roi_selection = uicontrol('Parent',h.fig,'Style','popupmenu','String',{'Displayed ROIs','All ROIs'},...
                'Units','Pixels','Position',[65 55 110 25],'BackgroundColor',[1 1 1]);
            
            thresh_chkbx = uicontrol('Parent',h.fig,'Style','Checkbox','String','Use Noise Thresholding ?','Units','pixels',...
                'Position',[15 115 160 25],'Min',0,'Max',1,'Callback',@use_threshold_Callback);
            set(thresh_chkbx,'Value',get(thresh_chkbx,'Min'));
            use_thresh=get(thresh_chkbx,'Value');
            
           br_frq=uicontrol('Parent',h.fig,'Style','edit','String','2.5','Units','pixels','Position',[355 135 25 25],...
                'BackgroundColor',[1 1 1]);
            uicontrol('Parent',h.fig,'Style','text','String','B frq','Units','pixels',...
                'HorizontalAlignment','left','Position',[355 160 100 15],'TooltipString','Breathing frequency upper limit (Hz) Set to 0 for no limit');
                        
            use_epoch=uicontrol('Parent',h.fig,'Style','popupmenu','String',{'during','all','before','after'},...
                'Units','pixels','Position',[355 85 75 25],'BackgroundColor',[1 1 1]);
            uicontrol('Parent',h.fig,'Style','text','String','Epoch ?','Units','pixels',...
                'HorizontalAlignment','left','Position',[355 110 50 15]);
            
            choose_odor=uicontrol('Parent',h.fig,'Style','listbox','String',[od_list, 'All_odors'],...
                'Units','pixels','Position',[458 75 100 85],'BackgroundColor',[1 1 1],'Min',1,'Max',length(od_list)+1);
            uicontrol('Parent',h.fig,'Style','text','String','Odor ?','Units','pixels',...
                'HorizontalAlignment','left','Position',[458 160 100 15]);
            
            h.disp_lat=uicontrol('Parent',h.fig,'Style','checkbox','String','Plot latency ?','Units','pixels',...
                'Position',[205 150 100 20],'Value',0);
            h.disp_rise=uicontrol('Parent',h.fig,'Style','checkbox','String','Plot rise-time ?','Units','pixels',...
                'Position',[205 130 100 20],'Value',0);
            
                        
            uicontrol('Parent',h.fig,'style','text','string','Set Xlim','units','pixels','position',[408 55 50 15]);
            uicontrol('Parent',h.fig,'style','text','string','Set Ylim1','units','pixels','position',[408 35 50 15]);
            uicontrol('Parent',h.fig,'style','text','string','Set Ylim2','units','pixels','position',[408 15 50 15]);
            h.set_xlim.low=uicontrol('Parent',h.fig,'Style','edit','String','','Units','pixels',...
                'Position',[458 55 50 20],'BackgroundColor',[1 1 1]);
            h.set_xlim.high=uicontrol('Parent',h.fig,'Style','edit','String','','Units','pixels',...
                'Position',[508 55 50 20],'BackgroundColor',[1 1 1]);
            h.set_ylim1.low=uicontrol('Parent',h.fig,'Style','edit','String','','Units','pixels',...
                'Position',[458 35 50 20],'BackgroundColor',[1 1 1]);
            h.set_ylim1.high=uicontrol('Parent',h.fig,'Style','edit','String','','Units','pixels',...
                'Position',[508 35 50 20],'BackgroundColor',[1 1 1]);
            h.set_ylim2.low=uicontrol('Parent',h.fig,'Style','edit','String','','Units','pixels',...
                'Position',[458 15 50 20],'BackgroundColor',[1 1 1]);
            h.set_ylim2.high=uicontrol('Parent',h.fig,'Style','edit','String','','Units','pixels',...
                'Position',[508 15 50 20],'BackgroundColor',[1 1 1]);
            
            uicontrol('Parent',h.fig,'style','text','string','Fixed flow ?','units','pixels','position',[2 32 65 15]);
            h.fix_flow = uicontrol('Parent',h.fig,'Style','edit','String','',...
                'Units','Pixels','Position',[65 30 110 25],'BackgroundColor',[1 1 1]);
            
            
            uicontrol('Parent',h.fig,'Style','pushbutton','String','GO !','Units','pixels',...
                'Position',[250 10 70 30],'Callback',@go_Callback); 


        end
        
        function exp_2_wrkspce_Callback(varargin)
            use_exp_2_wrkspce=get(exp_2_wrkspce,'Value');
        end
        
        function exp_2_file_Callback(varargin)
            use_exp_2_file=get(exp_2_file,'Value');
        end
        
        function use_threshold_Callback(varargin)
            use_thresh=get(thresh_chkbx,'Value');
        end
        
        function make_fig_Callback(varargin)
            use_makefig=get(make_fig,'Value');
        end

        function amplitudes=noise_thresholding(amp_vector,roi_vector,doit)
           o=interface.getOlfact();
           use_rois=interface.getCurrentRois();
           noise_threshold=get_pre_odor_noise_thresh(o,use_rois);
           amplitudes=amp_vector;
           if doit==1
               for k=1:length(use_rois)
                    amplitudes(amplitudes<=noise_threshold(k) & roi_vector==use_rois(k))=NaN;
               end
           end
           amplitudes=num2cell(amplitudes)';
            
        end
        
        function go_Callback(varargin)
            
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            use_rois=interface.getCurrentRois();
            sel_trials=interface.getSelectedItems();
            tr=[o.trials];de=[tr.detail];
            on=unique({de.odorant_name});
%             olf = o; trials = olf.trials; mes = [trials.measurement]; det=[trials.detail]; session=unique({det.session});
%             [ods,~,od_ind] = unique({det.odorant_name});
%             howmanyodors=length(ods);
            switch get(trial_selection,'Value')
                                   
                
        %%%%%%%% CASE "ALL TRIALS"
                case 1
                    olf = o; trials = olf.trials; mes = [trials.measurement]; det=[trials.detail]; session=unique({det.session});
                    [ods,~,od_ind] = unique({det.odorant_name});
                    howmanyodors=length(ods);
%% IF EXPORT TO FILE
                    if use_exp_2_file
                        [filename pathname] = uiputfile('.olf','Save current trial',o.trials.detail.session);
                    end
%%% END IF FILE                    
%%
                    for i=1:howmanyodors
                        submes=mes(od_ind==i);subtrials=trials(od_ind==i);
                        subfits=[submes.response_fits];
                        skimtimestamps=[];
                        skimonset=[];skimoffset=[];
                        skimtrial_num=[];skimtrial_name=[];
                        for n = 1:length(subtrials)
                            subtimestamps=repmat(subtrials(n).timestamp,length(submes(n).response_fits),1);
                            subonset=repmat(submes(n).odor_onoff.odor_onset,length(submes(n).response_fits),1);
                            suboffset=repmat(submes(n).odor_onoff.odor_offset,length(submes(n).response_fits),1);
                            subtrial_num=repmat(n,length(submes(n).response_fits),1);
                            subtrial_name=repmat(subtrials(n).name,length(submes(n).response_fits),1);
                            skimtimestamps=[skimtimestamps;subtimestamps]; %#ok<*AGROW>
                            skimonset=[skimonset;subonset];skimoffset=[skimoffset;suboffset];
                            skimtrial_num=[skimtrial_num;subtrial_num];skimtrial_name=[skimtrial_name;cellstr(subtrial_name)];
                        end
                       % skimfits=cell(length(subfits),8); %#ok<*NASGU>
                       % skimtrial_name=cellstr(skimtrial_name);
                        
                        switch get(roi_selection,'Value')
                            
                            
           %%%%%%%%% CASE "SELECTED ROIS"
                            case 1
                                                    
                                use_subfits=[];use_skimtimestamps=[];use_skimonset=[];use_skimoffset=[];use_skimtrial_num=[];use_skimtrial_name=[];
                                for j=1:length(use_rois)
                                    subrois=[subfits.roi_num]';
                                    use_subfits=[use_subfits subfits([subfits.roi_num]==use_rois(j))];
                                    use_skimtimestamps=[use_skimtimestamps; skimtimestamps(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimonset=[use_skimonset; skimonset(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimoffset=[use_skimoffset; skimoffset(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimtrial_num=[use_skimtrial_num; skimtrial_num(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimtrial_name=[use_skimtrial_name; skimtrial_name(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                end
                                subodor=repmat(ods(i),length(use_subfits),1);
                                disp_rois=num2str(use_rois);
                                
        %%%%%%%%%%%% CASE "ALL ROIS"
                            case 2
                                use_skimtimestamps = skimtimestamps;use_subfits = subfits;
                                use_skimonset=skimonset;use_skimoffset=skimoffset;
                                use_skimtrial_num=skimtrial_num;use_skimtrial_name=skimtrial_name;
                                subodor=repmat(ods(i),length(use_subfits),1);
                                disp_rois='All ROIs'; 
                        end
                        
                        odor_pres=cell(length(use_subfits),1);sniff_num=cell(length(use_subfits),1);
                        session_name=repmat(session,length(use_subfits),1);
                        % if you get a CAT error here (line226) it is probably
                        % because you have [] in your flowrates instead of
                        % NaNs. Redo the response fits to fix.
                        if length([use_subfits.t_10]) < length(use_subfits)
                            use_t10=zeros(1,length(use_subfits));
                            use_t10(1:length([use_subfits.t_10]))=[use_subfits.t_10];
                        else
                            use_t10=[use_subfits.t_10];
                        end
                            
                            
                        skimfits_nan=[subodor,num2cell(use_skimtimestamps),num2cell(use_skimtrial_num),num2cell([use_subfits.roi_num]'),...
                            sniff_num,num2cell([use_subfits.start]'),num2cell([use_subfits.y_offset]'),noise_thresholding([use_subfits.rise_amplitude],[use_subfits.roi_num],use_thresh),...
                            num2cell([use_subfits.flowrate_mag]'),num2cell([use_subfits.flowrate_diff]'),odor_pres,cellstr(use_skimtrial_name),session_name,...
                            num2cell([use_subfits.start]'-[use_subfits.stimtime]'+use_t10'),num2cell([use_subfits.rise_time]')];
                        
                        odor_onoff=cell2mat([num2cell(use_skimonset) num2cell(use_skimoffset)]);
                        startmat=cell2mat(skimfits_nan(:,6));
                        is_bef_dur_aft=[startmat<odor_onoff(:,1),startmat>=odor_onoff(:,1) & startmat<odor_onoff(:,2),startmat>=odor_onoff(:,2)];
                        skimfits_nan(is_bef_dur_aft(:,1),11)={'before'};
                        skimfits_nan(is_bef_dur_aft(:,2),11)={'during'};
                        skimfits_nan(is_bef_dur_aft(:,3),11)={'after'};
                        % now making a vector containing the number of the sniff 
                        bloc_lim=[0;find(is_bef_dur_aft(2:end,1)==1 & is_bef_dur_aft(1:end-1,3)==1);length(is_bef_dur_aft)]; %getting indices of each trial, sniffwise
                        use_sniff_num=[];
                        for n=1:length(bloc_lim)-1
                            use_sniff_num=[use_sniff_num 1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),1))) 1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),2)))...
                                1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),3)))];
                        end %there, done
                        skimfits_nan(:,5)=num2cell(use_sniff_num'); %inserting sniff_num vector into data array.
                        skimfits_mat=cell2mat(skimfits_nan(:,8:10)); %taking amplitude and both flow values into a matrix
                        flow_is_not_nan_mat=(~isnan(skimfits_mat(:,1)) & ~isnan(skimfits_mat(:,2)) & ~isnan(skimfits_mat(:,3))); %using said matrix to detect NaN in flow values
                        skimfits=skimfits_nan(flow_is_not_nan_mat,:); % stripping data set from lines containing NaN values for flow
                        thestructure=cell2struct(skimfits,{'odor' 'timestamp' 'trial_num' 'roi' 'sniff_num' 'start' 'offset' 'amplitude' 'flow_mag' 'flow_diff' 'odor_pres' 'trial_name' 'session' 'delay' 'rise_time'},2);
                        finalstructure=struct('before',thestructure(strcmp({thestructure.odor_pres},'before')),...
                            'during',thestructure(strcmp({thestructure.odor_pres},'during')),'after',thestructure(strcmp({thestructure.odor_pres},'after')));
%% IF EXPORT TO WORKSPACE                        
                        if use_exp_2_wrkspce
                            assignin('base',strrep(ods{i},' ','_'),finalstructure);
                        end
%%% END IF WRKSPCE                       
                        
%% IF MAKE FIGURES
                        use_odor=get(choose_odor,'Value');
                        if use_makefig && ismember(i,use_odor)
                             freq=str2double(get(br_frq,'String'));
                             epoch=get(use_epoch,'Value');
                             %this_odor=get(use_odor,'Value')
                             
                             arg_st=struct('freq',freq,'noise',use_thresh,'xlim',h.set_xlim,'ylim1',h.set_ylim1,'ylim2',h.set_ylim2,'fix_flow',h.fix_flow,'first',h.first_only,'latency',h.disp_lat,'rise',h.disp_rise);
                             switch epoch
                                 case 1
                                    flowrate_analysis(finalstructure,'during',arg_st)
                                 case 2
                                     flowrate_analysis(finalstructure,'before',arg_st)
                                     flowrate_analysis(finalstructure,'during',arg_st)
                                     flowrate_analysis(finalstructure,'after',arg_st)
                                 case 3
                                     flowrate_analysis(finalstructure,'before',arg_st)
                                 case 4
                                     flowrate_analysis(finalstructure,'after',arg_st)
                             end
                             
                        end
%%% END IF FIG

%% IF EXPORT TO FILE
                        if use_exp_2_file
                            lastructure=cell2struct(skimfits,{'odor' 'timestamp' 'trial_num' 'roi' 'sniff_num' 'start' 'offset' 'amplitude' 'flow_mag' 'flow_diff' 'odor_pres' 'trial_name' 'session'},2); %#ok<NASGU>
                            fullfilename = fullfile(pathname,strcat(filename(1:end-4),'_',ods{i},'.olf'));
                            save(fullfilename,'lastructure','-mat');
                        end
%%% END IF FILE                        
                        
                        if i==1
                            all_odors=thestructure;
                        elseif i>1
                            all_odors=[all_odors; thestructure];
                        end
                    end
                        
                    all_od_pres=struct('before',all_odors(strcmp({all_odors.odor_pres},'before')),'during',all_odors(strcmp({all_odors.odor_pres},'during')),...
                        'after',all_odors(strcmp({all_odors.odor_pres},'after')));
%% IF EXPORT TO WORKSPACE
                    if use_exp_2_wrkspce
                    assignin('base','all_odors',all_od_pres);
                    assignin('base','fits_n_flows',all_odors);
                    assignin('base','olf',olf);
                    disp(['exported session ' o.trials.detail.session ' to workspace as ''olf'', ROIs: ' disp_rois]);
                    end
%%% END IF WRKSPCE
                    
%% IF MAKE FIGURES                    
                    if use_makefig && ismember(howmanyodors+1,use_odor)
                       freq=str2double(get(br_frq,'String'));
                       epoch=get(use_epoch,'Value');
                       
                       arg_st=struct('freq',freq,'noise',use_thresh,'xlim',h.set_xlim,'ylim1',h.set_ylim1,'ylim2',h.set_ylim2,'fix_flow',h.fix_flow,'first',h.first_only);
                       switch epoch
                           case 1
                               flowrate_analysis(all_od_pres,'during',arg_st)
                           case 2
                               flowrate_analysis(all_od_pres,'before',arg_st)
                               flowrate_analysis(all_od_pres,'during',arg_st)
                               flowrate_analysis(all_od_pres,'after',arg_st)
                           case 3
                               flowrate_analysis(all_od_pres,'before',arg_st)
                           case 4
                               flowrate_analysis(all_od_pres,'after',arg_st)
                       end
                    end
%%% END IF FIG
       
%% IF EXPORT TO FILE                    
                    if use_exp_2_file
                        fullfilename = fullfile(pathname,filename);
                        save(fullfilename,'olf','-mat');
                        disp(['saved current session to file: ' filename ', ROIs: ' disp_rois]);
                    end
%%% END IF FILE  





%%        %%%%%%%%% CASE "SELECTED TRIALS"

                case 2
                    olf = o; trials = olf.trials(sel_trials); mes = [trials.measurement]; det=[trials.detail]; session=unique({det.session});
                    [ods,~,od_ind] = unique({det.odorant_name});
                    howmanyodors=length(ods);
                    
%% IF EXPORT TO FILE
                    if use_exp_2_file
                        [filename pathname] = uiputfile('.olf','Save current trial',o.trials.detail.session);
                    end
%%% END IF FILE                    
%%
                    for i=1:howmanyodors
                        submes=mes(od_ind==i);subtrials=trials(od_ind==i);
                        subfits=[submes.response_fits];
                        skimtimestamps=[];
                        skimonset=[];skimoffset=[];
                        skimtrial_num=[];skimtrial_name=[];
                        for n = 1:length(subtrials)
                            subtimestamps=repmat(subtrials(n).timestamp,length(submes(n).response_fits),1);
                            subonset=repmat(submes(n).odor_onoff.odor_onset,length(submes(n).response_fits),1);
                            suboffset=repmat(submes(n).odor_onoff.odor_offset,length(submes(n).response_fits),1);
                            subtrial_num=repmat(n,length(submes(n).response_fits),1);
                            subtrial_name=repmat(subtrials(n).name,length(submes(n).response_fits),1);
                            skimtimestamps=[skimtimestamps;subtimestamps]; %#ok<*AGROW>
                            skimonset=[skimonset;subonset];skimoffset=[skimoffset;suboffset];
                            skimtrial_num=[skimtrial_num;subtrial_num];skimtrial_name=[skimtrial_name;cellstr(subtrial_name)];
                        end
                       % skimfits=cell(length(subfits),8); %#ok<*NASGU>
                       % skimtrial_name=cellstr(skimtrial_name);
                        
                        switch get(roi_selection,'Value')
                            
                            
           %%%%%%%%% CASE "SELECTED ROIS"
                            case 1
                                                    
                                use_subfits=[];use_skimtimestamps=[];use_skimonset=[];use_skimoffset=[];use_skimtrial_num=[];use_skimtrial_name=[];
                                for j=1:length(use_rois)
                                    subrois=[subfits.roi_num]';
                                    use_subfits=[use_subfits subfits([subfits.roi_num]==use_rois(j))];
                                    use_skimtimestamps=[use_skimtimestamps; skimtimestamps(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimonset=[use_skimonset; skimonset(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimoffset=[use_skimoffset; skimoffset(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimtrial_num=[use_skimtrial_num; skimtrial_num(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                    use_skimtrial_name=[use_skimtrial_name; skimtrial_name(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                end
                                subodor=repmat(ods(i),length(use_subfits),1);
                                disp_rois=num2str(use_rois);
                                
        %%%%%%%%%%%% CASE "ALL ROIS"
                            case 2
                                use_skimtimestamps = skimtimestamps;use_subfits = subfits;
                                use_skimonset=skimonset;use_skimoffset=skimoffset;
                                use_skimtrial_num=skimtrial_num;use_skimtrial_name=skimtrial_name;
                                subodor=repmat(ods(i),length(use_subfits),1);
                                disp_rois='All ROIs'; 
                        end
                        
                        odor_pres=cell(length(use_subfits),1);sniff_num=cell(length(use_subfits),1);
                        session_name=repmat(session,length(use_subfits),1);
                        
                        if length([use_subfits.t_10]) < length(use_subfits)
                            use_t10=zeros(1,length(use_subfits));
                            use_t10(1:length([use_subfits.t_10]))=[use_subfits.t_10];
                        end
                        skimfits_nan=[subodor,num2cell(use_skimtimestamps),num2cell(use_skimtrial_num),num2cell([use_subfits.roi_num]'),...
                            sniff_num,num2cell([use_subfits.start]'),num2cell([use_subfits.y_offset]'),noise_thresholding([use_subfits.rise_amplitude],[use_subfits.roi_num],use_thresh),...
                            num2cell([use_subfits.flowrate_mag]'),num2cell([use_subfits.flowrate_diff]'),odor_pres,cellstr(use_skimtrial_name),session_name,...
                            num2cell([use_subfits.start]'-[use_subfits.stimtime]'+use_t10'),num2cell([use_subfits.rise_time]')];
                        
                        odor_onoff=cell2mat([num2cell(use_skimonset) num2cell(use_skimoffset)]);
                        startmat=cell2mat(skimfits_nan(:,6));
                        is_bef_dur_aft=[startmat<odor_onoff(:,1),startmat>=odor_onoff(:,1) & startmat<odor_onoff(:,2),startmat>=odor_onoff(:,2)];
                        skimfits_nan(is_bef_dur_aft(:,1),11)={'before'};
                        skimfits_nan(is_bef_dur_aft(:,2),11)={'during'};
                        skimfits_nan(is_bef_dur_aft(:,3),11)={'after'};
                        % now making a vector containing the number of the sniff 
                        bloc_lim=[0;find(is_bef_dur_aft(2:end,1)==1 & is_bef_dur_aft(1:end-1,3)==1);length(is_bef_dur_aft)]; %getting indices of each trial, sniffwise
                        use_sniff_num=[];
                        for n=1:length(bloc_lim)-1
                            use_sniff_num=[use_sniff_num 1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),1))) 1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),2)))...
                                1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),3)))];
                        end %there, done
                        skimfits_nan(:,5)=num2cell(use_sniff_num'); %inserting sniff_num vector into data array.
                        skimfits_mat=cell2mat(skimfits_nan(:,8:10)); %taking amplitude and both flow values into a matrix
                        flow_is_not_nan_mat=(~isnan(skimfits_mat(:,1)) & ~isnan(skimfits_mat(:,2)) & ~isnan(skimfits_mat(:,3))); %using said matrix to detect NaN in flow values
                        skimfits=skimfits_nan(flow_is_not_nan_mat,:); % stripping data set from lines containing NaN values for flow
                        thestructure=cell2struct(skimfits,{'odor' 'timestamp' 'trial_num' 'roi' 'sniff_num' 'start' 'offset' 'amplitude' 'flow_mag' 'flow_diff' 'odor_pres' 'trial_name' 'session' 'delay' 'rise_time'},2);
                        finalstructure=struct('before',thestructure(strcmp({thestructure.odor_pres},'before')),...
                            'during',thestructure(strcmp({thestructure.odor_pres},'during')),'after',thestructure(strcmp({thestructure.odor_pres},'after')));
%% IF EXPORT TO WORKSPACE                        
                        if use_exp_2_wrkspce
                            assignin('base',strrep(ods{i},' ','_'),finalstructure);
                        end
%%% END IF WRKSPCE                       
                        
%% IF MAKE FIGURES
                        use_odor=get(choose_odor,'Value');
                        if use_makefig && ismember(find(strcmp(ods(i),on)),use_odor)
                             freq=str2double(get(br_frq,'String'));
                             epoch=get(use_epoch,'Value');
                             %this_odor=get(use_odor,'Value')
                             
                             arg_st=struct('freq',freq,'noise',use_thresh,'xlim',h.set_xlim,'ylim1',h.set_ylim1,'ylim2',h.set_ylim2,'fix_flow',h.fix_flow,'first',h.first_only,'latency',h.disp_lat,'rise',h.disp_rise);
                             switch epoch
                                 case 1
                                    flowrate_analysis(finalstructure,'during',arg_st)
                                 case 2
                                     flowrate_analysis(finalstructure,'before',arg_st)
                                     flowrate_analysis(finalstructure,'during',arg_st)
                                     flowrate_analysis(finalstructure,'after',arg_st)
                                 case 3
                                     flowrate_analysis(finalstructure,'before',arg_st)
                                 case 4
                                     flowrate_analysis(finalstructure,'after',arg_st)
                             end
                             
                        end
%%% END IF FIG

%% IF EXPORT TO FILE
                        if use_exp_2_file
                            lastructure=cell2struct(skimfits,{'odor' 'timestamp' 'trial_num' 'roi' 'sniff_num' 'start' 'offset' 'amplitude' 'flow_mag' 'flow_diff' 'odor_pres' 'trial_name' 'session'},2); %#ok<NASGU>
                            fullfilename = fullfile(pathname,strcat(filename(1:end-4),'_',ods{i},'.olf'));
                            save(fullfilename,'lastructure','-mat');
                        end
%%% END IF FILE                        
                        
                        if i==1
                            all_odors=thestructure;
                        elseif i>1
                            all_odors=[all_odors; thestructure];
                        end
                    end
                        
                    all_od_pres=struct('before',all_odors(strcmp({all_odors.odor_pres},'before')),'during',all_odors(strcmp({all_odors.odor_pres},'during')),...
                        'after',all_odors(strcmp({all_odors.odor_pres},'after')));
%% IF EXPORT TO WORKSPACE
                    if use_exp_2_wrkspce
                    assignin('base','all_odors',all_od_pres);
                    assignin('base','fits_n_flows',all_odors);
                    assignin('base','olf',olf);
                    disp(['exported session ' o.trials.detail.session ' to workspace as ''olf'', ROIs: ' disp_rois]);
                    end
%%% END IF WRKSPCE
                    
%% IF MAKE FIGURES                    
                    if use_makefig && ismember(length(on)+1,use_odor)
                       freq=str2double(get(br_frq,'String'));
                       epoch=get(use_epoch,'Value');
                    
                       arg_st=struct('freq',freq,'noise',use_thresh,'xlim',h.set_xlim,'ylim',h.set_ylim,'fix_flow',h.fix_flow,'first',h.first_only);
                       switch epoch
                           case 1
                               flowrate_analysis(all_od_pres,'during',arg_st)
                           case 2
                               flowrate_analysis(all_od_pres,'before',arg_st)
                               flowrate_analysis(all_od_pres,'during',arg_st)
                               flowrate_analysis(all_od_pres,'after',arg_st)
                           case 3
                               flowrate_analysis(all_od_pres,'before',arg_st)
                           case 4
                               flowrate_analysis(all_od_pres,'after',arg_st)
                       end
                    end
%%% END IF FIG
       
%% IF EXPORT TO FILE                    
                    if use_exp_2_file
                        fullfilename = fullfile(pathname,filename);
                        save(fullfilename,'olf','-mat');
                        disp(['saved current session to file: ' filename ', ROIs: ' disp_rois]);
                    end
%%% END IF FILE                         
                        
%%        %%%%%%%%% CASE "THIS TRIAL"                
                                
                case 3
                        onetrial = o.trials(t);
%% IF EXPORT TO WORKSPACE
                            if use_exp_2_wrkspce
                                assignin('base','trial',onetrial)
                                disp(['exported current trial ' onetrial.name ' to workspace as ''trial''']);
                            end
%%% END IF WRKSPCE

%% IF EXPORT TO FILE
                            if use_exp_2_file
                                [filename pathname] = uiputfile('.olf','Save current trial',onetrial.name);
                                fullfilename = fullfile(pathname,filename);
                                save(fullfilename,'onetrial','-mat');
                                disp(['saved current trial to file: ' filename]);
                            end
%%% END IF FILE                    

%% IF MAKE FIGURE
                            if use_makefig
                                use_rois=interface.getCurrentRois();
                                mes = [onetrial.measurement]; 
                                session={onetrial.detail.session};
                                odor={onetrial.detail.odorant_name};
                                fits=[mes.response_fits];
                                skimtimestamps=repmat(onetrial.timestamp,length(fits),1);
                                skimonset=repmat(mes.odor_onoff.odor_onset,length(fits),1);
                                skimoffset=repmat(mes.odor_onoff.odor_offset,length(fits),1);
                                skimtrial_name=cellstr(repmat(onetrial.name,length(fits),1));
                                skimtrial_num=ones(length(fits),1);

                                switch get(roi_selection,'Value')

               %%%%%%%%% CASE "SELECTED ROIS"
                                    case 1

                                        use_subfits=[];use_skimtimestamps=[];use_skimonset=[];use_skimoffset=[];use_skimtrial_name=[];use_skimtrial_num=[];
                                        for j=1:length(use_rois)
                                            subrois=[fits.roi_num]';
                                            use_subfits=[use_subfits fits([fits.roi_num]==use_rois(j))];
                                            use_skimtimestamps=[use_skimtimestamps; skimtimestamps(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                            use_skimonset=[use_skimonset; skimonset(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                            use_skimoffset=[use_skimoffset; skimoffset(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                            use_skimtrial_name=[use_skimtrial_name; skimtrial_name(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                            use_skimtrial_num=[use_skimtrial_num; skimtrial_num(find(subrois==use_rois(j)))]; %#ok<FNDSB>
                                        end
                                        subodor=repmat(odor,length(use_subfits),1);
    %                                     disp_rois=num2str(use_rois);

            %%%%%%%%%%%% CASE "ALL ROIS"
                                        case 2
                                            use_skimtimestamps = skimtimestamps;use_subfits = fits;
                                            use_skimonset=skimonset;use_skimoffset=skimoffset;
                                            use_skimtrial_name=skimtrial_name;
                                            subodor=repmat(odor,length(use_subfits),1);
                                            use_skimtrial_num=skimtrial_num;
        %                                     disp_rois='All ROIs'; 
                                end

                            odor_pres=cell(length(use_subfits),1);sniff_num=cell(length(use_subfits),1);
                            session_name=repmat(session,length(use_subfits),1);
                            if length([use_subfits.t_10]) < length(use_subfits)
                                use_t10=zeros(1,length(use_subfits));
                                use_t10(1:length([use_subfits.t_10]))=[use_subfits.t_10];
                            end
                            skimfits_nan=[subodor,num2cell(use_skimtimestamps),num2cell([use_subfits.roi_num]'),...
                                sniff_num,num2cell([use_subfits.start]'),num2cell([use_subfits.y_offset]'),noise_thresholding([use_subfits.rise_amplitude],[use_subfits.roi_num],use_thresh),...
                                num2cell([use_subfits.flowrate_mag]'),num2cell([use_subfits.flowrate_diff]'),odor_pres,cellstr(use_skimtrial_name),session_name,num2cell(use_skimtrial_num),...
                                num2cell([use_subfits.start]'-[use_subfits.stimtime]'+use_t10'),num2cell([use_subfits.rise_time]')];

                            odor_onoff=cell2mat([num2cell(use_skimonset) num2cell(use_skimoffset)]);
                            startmat=cell2mat(skimfits_nan(:,5));
                            is_bef_dur_aft=[startmat<odor_onoff(:,1),startmat>=odor_onoff(:,1) & startmat<odor_onoff(:,2),startmat>=odor_onoff(:,2)];
                            skimfits_nan(is_bef_dur_aft(:,1),10)={'before'};
                            skimfits_nan(is_bef_dur_aft(:,2),10)={'during'};
                            skimfits_nan(is_bef_dur_aft(:,3),10)={'after'};
                            % now making a vector containing the number of the sniff 
                            bloc_lim=[0;find(is_bef_dur_aft(2:end,1)==1 & is_bef_dur_aft(1:end-1,3)==1);length(is_bef_dur_aft)]; %getting indices of each trial, sniffwise
                            use_sniff_num=[];
                            for n=1:length(bloc_lim)-1
                                use_sniff_num=[use_sniff_num 1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),1))) 1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),2)))...
                                    1:length(find(is_bef_dur_aft(bloc_lim(n)+1:bloc_lim(n+1),3)))];
                            end %there, done
                            skimfits_nan(:,4)=num2cell(use_sniff_num'); %inserting sniff_num vector into data array.
                            skimfits_mat=cell2mat(skimfits_nan(:,7:9)); %taking amplitude and both flow values into a matrix
                            flow_is_not_nan_mat=(~isnan(skimfits_mat(:,1)) & ~isnan(skimfits_mat(:,2)) & ~isnan(skimfits_mat(:,3))); %using said matrix to detect NaN in flow values
                            skimfits=skimfits_nan(flow_is_not_nan_mat,:); % stripping data set from lines containing NaN values for flow
                            thestructure=cell2struct(skimfits,{'odor' 'timestamp' 'roi' 'sniff_num' 'start' 'offset' 'amplitude' 'flow_mag' 'flow_diff' 'odor_pres' 'trial_name' 'session' 'trial_num' 'delay' 'rise_time'},2);                        
                            finalstructure=struct('before',thestructure(strcmp({thestructure.odor_pres},'before')),...
                                'during',thestructure(strcmp({thestructure.odor_pres},'during')),'after',thestructure(strcmp({thestructure.odor_pres},'after')));

                            freq=str2double(get(br_frq,'String'));
                            epoch=get(use_epoch,'Value');
                            arg_st=struct('freq',freq,'noise',use_thresh,'xlim',h.set_xlim,'ylim1',h.set_ylim1,'ylim2',h.set_ylim2,'fix_flow',h.fix_flow,'first',h.first_only,'latency',h.disp_lat,'rise',h.disp_rise);
                            switch epoch
                                case 1
                                   flowrate_analysis(finalstructure,'during',arg_st)
                                case 2
                                    flowrate_analysis(finalstructure,'before',arg_st)
                                    flowrate_analysis(finalstructure,'during',arg_st)
                                    flowrate_analysis(finalstructure,'after',arg_st)
                                case 3
                                    flowrate_analysis(finalstructure,'before',arg_st)
                                case 4
                                    flowrate_analysis(finalstructure,'after',arg_st)
                            end
                             
                            end

%%% END IF FIG
            end
    end
    end
end