function olfactometry(varargin)
    VERSION = '0.6';
    if connect_existing_instance(varargin{:})
        return
    end

    h = make_figure;

    if ~ispref('GUI_positions','olfactometry')
        set_gui_positions;
    end
    prefpos = getpref('GUI_positions','olfactometry');

    function set_gui_positions
        prefpos = struct('fig',[60 60 1080 680],'lrpanels',[300 150],'rlpanel',0.5);
        setpref('GUI_positions','olfactometry',prefpos)
    end
    function reset_gui_positions(varargin)
        set_gui_positions
        size_window
    end
    function p = getPrefposOrDefault(id,p)
        if isfield(prefpos,id)
            p = prefpos.(id);
        end
    end
    function setPrefpos(id,p)
        prefpos.(id) = p;
    end
    
    o = olfact;
    currently_saved = true;
    saved_filepath = 'Untitled';
    suggested_filename = '';
    exts = struct;

    listeners = struct('after_startup',{{@size_window, @load_extensions}},...
        'after_load_olfact',{{@load_trial_listbox,@update_current_info,@clear_view}},...
        'before_unload_trial',{{@clear_view}},...
        'mainaxes_click',{{}},...
        'after_load_trial',{{@load_roi_listbox,@set_trialname_text,@draw_view}},...
        'before_save_olfact',{{}},...
        'before_exit',{{@clear_extensions,@stop_timer}});

    replace_trialname_text = timer('TimerFcn', @reset_trialname_text, 'StartDelay', 0.5);

    function register_event_listener(event,fcn)
        flash_in_status_bar(['registering ''' event ''': ' func2str(fcn)])
        listeners.(event) = listeners.(event)(~cellfun(@(f)isequal(fcn,f),listeners.(event))); %avoid duplicates
        listeners.(event) = [listeners.(event) {fcn}];
    end
    function unregister_event_listener(event,fcn)
        flash_in_status_bar(['unregistering ''' event ''': ' func2str(fcn)])
        listeners.(event) = listeners.(event)(~cellfun(@(f)isequal(fcn,f),listeners.(event)));
    end
    function fire_event(event)
        flash_in_status_bar(['firing ''' event ''''])
        if ~isfield(listeners,event)
            error('not valid event')
        end
        for n = 1:length(listeners.(event))
            listeners.(event){n}()
        end
    end

    function clear_extensions
        checktree_ext_clear_checked
        h.extension_checktree.clearTree()
        ext_queue = {};
        view_queue = {};
        exts = struct;
    end

    function load_extensions(varargin)
        files = what(fileparts(mfilename('fullpath')));
        matches = regexp(files.m,'.*_(extensions?|plugins?)(?=\.m)','match','once');
        fcns = cellfun(@(a){str2func(a)},matches(~cellfun(@isempty,matches)));
        clear_extensions
        groups = struct;
        extension_interface = struct('getBlankInitializer', @getBlankInitializer, 'add', @add_extension, ...
            'getOlfact', @getOlfact, 'updateOlfact', @updateOlfact, 'forceRedrawView', @redraw_view, ...
            'getCurrentTrial', @current_trial, 'getCurrentRois', @current_rois, 'getCurrentScaling', @getCurrentScaling, ...
            'register_event_listener', @register_event_listener, 'unregister_event_listener', @unregister_event_listener, ...
            'fig', h.fig, 'mainaxes', h.mainaxes, 'drawViewUid', @drawViewUid, 'getSelectedItems', h.trial_listbox.getSelectedItems, ...
            'getPrefposOrDefault', @getPrefposOrDefault, 'setPrefpos', @setPrefpos, 'set', @setUserValue, 'get', @getUserValue, ...
            'update_status_waitbar', @update_status_waitbar, 'clear_status_waitbar', @clear_status_waitbar);

        for ni = 1:length(fcns)
            try
                fcns{ni}(extension_interface);
            catch
                warning('olfactometry:errorLoadingExtension',['error loading ''' func2str(fcns{ni}) ''', skipping'])
                disp(lasterr)
            end
        end

        function init = getBlankInitializer
            init = struct('uid','','name','Unnamed','group','Unclassified','type','normal','prerequisites',{{}},'onDrawView',[],'onCheck',[],'onUncheck',[],'onRightClick',[],'onExecute',[]);
        end
        function add_extension(init)
            if ~strcmp(genvarname(init.uid),init.uid)
                warning('olfactometry:invalidExtensionUid',['invalid uid (''' init.uid ''' given), skipping'])
            elseif ismember(init.uid,fieldnames(exts))
                warning('olfactometry:duplicateUid',['uid already taken (''' init.uid ''' given), skipping'])
            else
                group = genvarname(init.group);
                if ~isfield(groups, group)
                    groups.(group) = h.extension_checktree.addGroup(init.group,[]);
                end
                init.ctrl_fcns = groups.(group).addCheck(init.name, false, make_ext_checktree_callback(init.uid));
                exts.(init.uid) = init;
            end
        end

        f = fieldnames(groups);
        for fi = 1:length(f)
            groups.(f{fi}).expandGroup();
        end
        h.extension_checktree.repaint()
        redraw_view
    end

    function cb = make_ext_checktree_callback(uid)
        cb = @(ev) checktree_ext_callback(ev, uid);
    end

    function checktree_ext_clear_checked
        f = fieldnames(exts);
        for fi = 1:length(f)
            if exts.(f{fi}).ctrl_fcns.getCheckState()
                exts.(f{fi}).ctrl_fcns.setCheckState(false,true)
                if isa(exts.(f{fi}).onUncheck,'function_handle')
                    exts.(f{fi}).onUncheck()
                end
            end
        end
    end

    function checktree_ext_callback(ev, uid)
        switch ev.type
            case 'checkChange'

                switch ev.state
                    case true
                        switch exts.(uid).type
                            case 'normal'
                                try
                                    add_to_ext_queue(uid);
                                    if isa(exts.(uid).onCheck,'function_handle')
                                        exts.(uid).onCheck()
                                    end
                                catch
                                    err = lasterror;
                                    switch err.identifier
                                        case 'Olfactometry:missingPrerequisite'
                                            exts.(uid).ctrl_fcns.setCheckState(~ev.state,true)
                                    end
                                    rethrow(lasterror)
                                end

                            case 'script'
                                exts.(uid).ctrl_fcns.setCheckState(~ev.state,true)
                                if isa(exts.(uid).onExecute,'function_handle')
                                    exts.(uid).onExecute()
                                end
                        end
                    case false
                        switch exts.(uid).type
                            case 'normal'
                                remove_from_ext_queue(uid);
                                if isa(exts.(uid).onUncheck,'function_handle')
                                    exts.(uid).onUncheck()
                                end
                        end
                end
                redraw_view

            case 'rightClick'
                if isa(exts.(uid).onRightClick,'function_handle')
                    delete(get(h.extension_menu,'Children'))
                    set(h.extension_menu, 'Position', calculate_popup_position(h.extension_checktree.box, ev.position))
                    exts.(uid).onRightClick(h.extension_menu);
                end
        end
    end

    ext_queue = {};
    view_queue = {};
    function add_to_ext_queue(uid)
        if ismember(uid,ext_queue)
            return
        end
        for pi = 1:length(exts.(uid).prerequisites)
            p = exts.(uid).prerequisites{pi};
            if ~ismember(p,ext_queue)
                if isfield(exts,p)
                    exts.(p).ctrl_fcns.setCheckState(true,false)
                else
                    error('Olfactometry:missingPrerequisite',['Extension ''' uid ''' requires unavailable function ''' p ''''])
                end
            end
        end
        flash_in_status_bar(['adding ' uid])
        ext_queue{end+1} = uid;
        if isa(exts.(uid).onDrawView, 'function_handle')
            view_queue{end+1} = uid;
        end
    end

    function remove_from_ext_queue(uid)
        [tf, loc] = ismember(uid, ext_queue);
        if ~tf
            return
        end
        li = loc+1;
        while li <= length(ext_queue)
            if ismember(uid,exts.(ext_queue{li}).prerequisites)
                exts.(ext_queue{li}).ctrl_fcns.setCheckState(false,false)
            else
                li = li + 1;
            end
        end
        flash_in_status_bar(['removing ' uid])
        ext_queue(loc) = [];
        if isa(exts.(uid).onDrawView, 'function_handle')
            view_queue = view_queue(~ismember(view_queue,uid));
        end
    end

    function reentry(varargin)
        figure(h.fig)
        if nargin
            switch varargin{1}
                case 'open'
                    if ischar(varargin{2}) && check_for_save
                        open_from_file_helper(varargin{2})
                    end
                case 'load'
                    if isa(varargin{2}, 'olfact') && length(varargin{2}) == 1 && check_for_save
                        o = varargin{2};
                        saved_filepath = 'Untitled';
                        currently_saved = isempty(o); %if nothing was imported, say it's saved
                        fire_event('after_load_olfact')
                    end
                case 'kill'
                    delete(h.fig)
            end
        end
    end

    function ImportMenu_Callback(varargin)
        delete(get(h.ImportMenuItem,'Children'))
        for t = import_types(o)
            uimenu(h.ImportMenuItem,'Label',t.preptype,'Callback',@ImportTypeMenuItem_Callback)
        end
    end

    function shouldcontinue = check_for_save
        prev_trial = current_trial;
        change_trial(0)
        shouldcontinue = true;
        while ~currently_saved
            switch questdlg('Do you want to save the current data?','Save?','Yes','No','Cancel','Yes')
                case 'Yes'
                    SaveMenuItem_Callback
                case 'No'
                    return
                case 'Cancel'
                    change_trial(prev_trial)
                    shouldcontinue = false;
                    return
            end
        end
    end

    function NewMenuItem_Callback(varargin)
        if check_for_save
            o = olfact;
            saved_filepath = 'Untitled';
            currently_saved = true;
            fire_event('after_load_olfact')
        end
    end

    function ImportTypeMenuItem_Callback(varargin)
        hObject = varargin{1};
        [new_o, suggested_filename] = import(olfact,get(hObject,'Label'),@update_status_waitbar);
        o = [o new_o];
        clear_status_waitbar
        currently_saved = currently_saved && isempty(o); %if nothing was imported, say it's saved
        fire_event('after_load_olfact')
    end

    function delete_trials_Callback(varargin)
        sel_tr = h.trial_listbox.getSelectedItems();
        if ~isempty(sel_tr)
            if strcmp(questdlg('Are you sure you want to delete the trial(s)?','Confirm delete','Yes','No','No'),'Yes')
                fire_event('before_unload_trial')
                o = delete_trials(o,sel_tr);
                unsave
                fire_event('after_load_olfact')
            end
        end
    end

    function OpenMenuItem_Callback(varargin)
        if check_for_save
            if ~ispref('Olfactometry','previous_save_directory')
                setpref('Olfactometry','previous_save_directory','')
            end
            [filename, pathname] = uigetfile({'*.olf','Olfactory file'},'Open',getpref('Olfactometry','previous_save_directory'));
            if ~isequal(filename, 0)
                filepath = fullfile(pathname, filename);
                setpref('Olfactometry','previous_save_directory',pathname)
                open_from_file_helper(filepath)
            end
        end
    end

    function open_from_file_helper(filepath) %Doesn't check if current object is saved!
        w = warning('query','MATLAB:load:variableNotFound'); %handle our own warning
        warning('off','MATLAB:load:variableNotFound')
        try
            S = load('-mat',filepath,'o'); %just load default name - not backwards compatible
        catch
            errordlg('This file isn''t valid.','File Error')
        end
        if isfield(S,'o')
            o = S.o;
            saved_filepath = filepath;
            currently_saved = true;
            fire_event('after_load_olfact')
        else
            errordlg('The file doesn''t contain an olfact object.','File Error')
        end
        warning(w)
    end

    function SaveMenuItem_Callback(varargin)
        if strcmp(saved_filepath,'Untitled')
            SaveAsMenuItem_Callback
        else
            fire_event('before_save_olfact')
            save(saved_filepath,'o');
            currently_saved = true;
        end
        update_current_info
    end

    function SaveAsMenuItem_Callback(varargin)
        if ~ispref('Olfactometry','previous_save_directory')
            setpref('Olfactometry','previous_save_directory','')
        end
        [filename, pathname] = uiputfile({'*.olf','Olfactory file'},'Save As',fullfile(getpref('Olfactometry','previous_save_directory'),[suggested_filename '.olf']));
        if ~isequal(filename,0)
            saved_filepath = fullfile(pathname, filename);
            setpref('Olfactometry','previous_save_directory',pathname)
            SaveMenuItem_Callback
        end
    end

    function LoadFromWorkspaceMenuItem_Callback(varargin)
        if check_for_save
            vars = evalin('base','whos');
            var = {vars(strcmp({vars.class},'olfact')).name};
            sel = listdlg('ListString',var,'SelectionMode','single','Name','Select variable','OKString','Import');
            if ~isempty(sel)
                o = evalin('base',var{sel});
                saved_filepath = 'Untitled';
                currently_saved = isempty(o); %if nothing was imported, say it's saved
                fire_event('after_load_olfact')
            end
        end
    end

    function SaveToWorkspaceMenuItem_Callback(varargin)
        %find next available 'olf#'
        suffix = '';
        counter = 0;
        while evalin('base', ['exist(''olf' suffix ''',''var'')'])
            counter = counter + 1;
            suffix = int2str(counter);
        end
        assignin('base','olfact',o);
    end

    function CloseMenuItem_Callback(varargin)
        if check_for_save
            fire_event('before_exit')
            %save current columns/widths
            cur_cols = h.trial_listbox.get_columns();
            if ~isempty(cur_cols)
                setpref('Olfactometry','listbox_columns',cur_cols)
            end
            h.trial_listbox.refresh_column_lookup_pref();

            prefpos.fig = get(h.fig,'Position');
            setpref('GUI_positions','olfactometry',prefpos)
            delete(h.fig)
            h = [];
        end
    end

    function update_status_waitbar(n)
        set(h.statuswait,'XData',[0 n n 0]) % n between 0 and 1
        drawnow
    end

    function clear_status_waitbar
        set(h.statuswait,'EraseMode','normal','XData',[0 0 0 0],'EraseMode','none')
    end

    function unsave
        currently_saved = false;
        update_current_info
    end

    function update_current_info
        if currently_saved
            saved = '';
        else
            saved = '*';
        end
        set(h.fig,'Name',['Olfactometry ' VERSION ' - ' saved_filepath saved])
    end

    columns_already_set = false;

    function load_trial_listbox
        if isempty(o.trials)
            h.trial_listbox.clear_data();
        else
            h.trial_listbox.set_column_lookup_pref('Olfactometry','listbox_column_lookup')
            data = extract_trial_info(o);
            h.trial_listbox.set_data(fieldnames(data), squeeze(struct2cell(data))', 'name')
            h.trial_listbox.setMouseClickCallback(@trial_clicked)

            if ispref('Olfactometry','listbox_columns') && ~columns_already_set
                h.trial_listbox.set_columns(getpref('Olfactometry','listbox_columns'))
                columns_already_set = true;
            end
        end
    end

    function update_trial_listbox(varargin)
        if isempty(o.trials)
            h.trial_listbox.clear_data();
        else
            h.trial_listbox.update_data(squeeze(struct2cell(extract_trial_info(o)))');
            h.trial_listbox.setSelectedItem(current_trial)
        end
    end

    function edit_trial_comment(varargin)
        sel = h.trial_listbox.getSelectedItems();
        if length(sel) == 1
            newcomment = input_dialog(['Edit comment for ' o.trials(sel).name],{''},{{o.trials(sel).detail.comment}},400);
            [o, wasmodified] = set_trial_detail(o,sel,'comment',newcomment{1}{1});
            if wasmodified
                unsave
                update_trial_listbox
            end
        end
    end

    function trial_clicked(ev)
        sel = ev.getSelectedItems();
        switch ev.type
            case 'leftClick'
                if ~isempty(sel)
                    change_trial(sel(end))
                end
            case 'rightClick'
                set(h.itemmenu,'Position',ev.getPosition(),'Visible','on')
            case 'doubleClick'
                edit_trial_comment
        end
    end

    function next_trial_Callback(varargin)
        h.trial_listbox.selectNext()
        sel = h.trial_listbox.getSelectedItems();
        change_trial(sel);
    end

    function previous_trial_Callback(varargin)
        h.trial_listbox.selectPrev()
        sel = h.trial_listbox.getSelectedItems();
        change_trial(sel);
        assignin('base','test',data);
    end

    current_trial_internal = 0;
    function change_trial(new_trial)
        if new_trial == current_trial_internal
            return
        else
            fire_event('before_unload_trial')
            if isempty(new_trial) || new_trial < 1 || new_trial > length(o.trials)
                current_trial_internal = 0;
            else
                current_trial_internal = new_trial;
                fire_event('after_load_trial')
            end
        end
    end
    function t = current_trial
        t = current_trial_internal;
    end

    function load_roi_listbox
        ri = get(h.roi_listbox,'Value');
        rois = o.rois(o.trials(current_trial).rois.nums);
        new_rois = arrayfun(@(a) {[num2str(rois(a).index) ' - ' rois(a).name]},1:length(rois));
        set(h.roi_listbox,'String',new_rois,'Value',ri(ri <= length(new_rois)))
    end

    trialname_text_string = '';
    function set_trialname_text
        if isempty(o.trials) || current_trial == 0
            trialname_text_string = '';
        else
            trialname_text_string = [num2str(current_trial) ': ' o.trials(current_trial).name];
        end
        reset_trialname_text
    end

    function reset_trialname_text(varargin)
        set(h.trialname_text,'String',trialname_text_string)
    end

    function ri = current_rois
        ri = get(h.roi_listbox,'Value');
    end

    function scale = getCurrentScaling
        scale = get(h.scale_slider,'Value');
    end

    function olf = getOlfact
        olf = o;
    end

    function updateOlfact(varargin)
        o = update(o, varargin{:});
        flash_in_status_bar('Updating...')
        unsave
    end

    user_values = {};
    function setUserValue(k,v)
        [tf, loc] = ismember(k,user_values(1:2:end));
        if tf
            user_values{2*loc} = v;
        else
            user_values(end+[1 2]) = {k,v};
        end
    end
    function v = getUserValue(k)
        [tf, loc] = ismember(k,user_values(1:2:end));
        if tf
            v = user_values{2*loc};
        else
            v = [];
        end
    end
    function redraw_view(varargin)
        clear_view
        draw_view
    end
    function clear_view
%        user_values = {};
        delete(allchild(h.mainaxes))
    end
    function extract_plot(varargin)
        if current_trial > 0
            a = axes('Parent',figure,'Box', 'on', 'NextPlot', 'add', 'YTick', [], 'Layer', 'top');
            title(a,o.trials(current_trial).name, 'Interpreter', 'none')
            for vi = 1:length(view_queue)
                exts.(view_queue{vi}).onDrawView(a)
            end
            %do ordering based on Userdata property
            c = get(a,'Children');
            ud = get(c,'Userdata');
            if iscell(ud)
                ud(cellfun(@(e) isempty(e) || ~isnumeric(e),ud)) = {0};
                [b, ix] = sort(cell2mat(ud),'descend');
                set(a,'Children',c(ix));
            end
        end
    end
    function draw_view
        if current_trial > 0
            for vi = 1:length(view_queue)
                exts.(view_queue{vi}).onDrawView(h.mainaxes)
            end
            %do ordering based on Userdata property
            c = get(h.mainaxes,'Children');
            ud = get(c,'Userdata');
            if iscell(ud)
                ud(cellfun(@(e) isempty(e) || ~isnumeric(e),ud)) = {0};
                [b, ix] = sort(cell2mat(ud),'descend');
                set(h.mainaxes,'Children',c(ix));
            end
        end
    end
    function drawViewUid(uid)
        if current_trial > 0 && isfield(exts,uid) && isa(exts.(uid).onDrawView, 'function_handle')
            exts.(uid).onDrawView(h.mainaxes)
            %do ordering based on Userdata property
            c = get(h.mainaxes,'Children');
            ud = get(c,'Userdata');
            if iscell(ud)
                ud(cellfun(@(e) isempty(e) || ~isnumeric(e),ud)) = {0};
                [b, ix] = sort(cell2mat(ud),'descend');
                set(h.mainaxes,'Children',c(ix));
            end
        end
    end

    function roi_listbox_select_all_Callback(varargin)
        set(h.roi_listbox,'Value',1:length(get(h.roi_listbox,'String')))
        roi_listbox_Callback
    end
    function roi_listbox_Callback(varargin)
        redraw_view
    end
    function scale_slider_Callback(varargin)
        redraw_view
    end


    %% ---------------------------------- edit details module --------------------------------------
    function edit_details_Callback(varargin)
        switch get(h.edit_details,'Value')
            case 1
                edit_details_on
            case 0
                edit_details_off
        end
    end
    edit_details_h = struct('fig',[]);
    edit_details_extracted_details = struct([]);
    function edit_details_on(varargin)
        set(h.edit_details,'Value',1)
        register_event_listener('after_load_olfact',@edit_details_refresh_fields)
        register_event_listener('before_exit',@edit_details_off)
        edit_details_h.fig = figure('Name','Details','Units','pixels',...
            'Position',getPrefposOrDefault('edit_details_box',[400 400 150 300]),...
            'MenuBar', 'none', 'DockControls','off',...
            'HandleVisibility','off','NumberTitle', 'off', ...
            'CloseRequestFcn',@edit_details_off,'ResizeFcn',@edit_details_resize, ...
            'Color', get(0,'DefaultUicontrolBackgroundColor'));
        edit_details_h.name_popupmenu = uicontrol('Parent',edit_details_h.fig, 'Style', 'popupmenu',...
            'BackgroundColor', [1 1 1], 'Callback', @edit_details_name_popupmenu_Callback, ...
            'TooltipString', 'Select a detail field to edit');
        edit_details_h.details_list = uicontrol('Parent',edit_details_h.fig, 'Style', 'listbox', ...
            'Min',1,'Max',1,'BackgroundColor', [1 1 1], 'Callback', @edit_details_choices_Callback, ...
            'TooltipString', 'Select a value to assign to the selected trials');
        edit_details_h.assign_button = uicontrol('Parent',edit_details_h.fig, 'Style', 'pushbutton', ...
            'String','Assign to selected trials','Callback', @edit_details_assign_Callback,...
            'TooltipString', 'Assign the selected value to the trials selected in the main window');
        edit_details_refresh_fields
        edit_details_resize
    end
    function edit_details_off(varargin)
        set(h.edit_details,'Value',0)
        unregister_event_listener('after_load_olfact',@edit_details_refresh_fields)
        unregister_event_listener('before_exit',@edit_details_off)
        if ishandle(edit_details_h.fig)
            setPrefpos('edit_details_box',get(edit_details_h.fig,'Position'));
            delete(edit_details_h.fig)
            edit_details_h.fig = [];
        end
    end
    function edit_details_resize(varargin)
        if isempty(edit_details_h.fig) || ~ishandle(edit_details_h.fig)
            return
        end
        figpos = get(edit_details_h.fig,'Position');
        set(edit_details_h.name_popupmenu,'Position',getpos(figpos,[0 1 1 0],[3 -23 -4 21]));
        set(edit_details_h.details_list,'Position',getpos(figpos,[0 0 1 1],[3 27 -4 -50]));
        set(edit_details_h.assign_button,'Position',getpos(figpos,[0 0 1 0],[3 2 -4 22]));
    end
    function edit_details_refresh_fields(varargin)
        if nargin == 0 || varargin{1} ~= false
            edit_details_extracted_details = extract_trial_details(o);
        end
        set(edit_details_h.name_popupmenu,'String',{edit_details_extracted_details.name '[add new field]'})
        edit_details_name_popupmenu_Callback
    end
    edit_details_current_field = [];
    function edit_details_name_popupmenu_Callback(varargin)
        sel = get(edit_details_h.name_popupmenu,'Value');
        if sel > length(edit_details_extracted_details)
            resp = input_dialog('New Field',{'Field name:', 'Has numeric values?'},{'',false},300);
            if isempty(resp{1})
                set(edit_details_h.name_popupmenu,'Value',edit_details_current_field)
                return
            end
            if resp{2}
                edit_details_extracted_details(end+1) = struct('name',resp{1},'numeric',true,'choices',[]);
            else
                edit_details_extracted_details(end+1) = struct('name',resp{1},'numeric',false,'choices',{{}});
            end
            edit_details_refresh_fields(false)
        else
            edit_details_current_field = sel;
            if edit_details_extracted_details(sel).numeric
                opt_cellstr = cellfun(@(a){num2str(a)},num2cell(edit_details_extracted_details(sel).choices));
            else
                opt_cellstr = edit_details_extracted_details(sel).choices;
            end
            set(edit_details_h.details_list,'Value',1,'String',[opt_cellstr '[remove detail]' '[add new value]'])
        end
    end
    function edit_details_choices_Callback(varargin)
        sel = get(edit_details_h.details_list,'Value');
        if sel > length(edit_details_extracted_details(edit_details_current_field).choices) + 1
            resp = input_dialog('New Value',{['New value for field ''' edit_details_extracted_details(edit_details_current_field).name ''':']},{''},300);
            if isempty(resp{1})
                return
            end
            if edit_details_extracted_details(edit_details_current_field).numeric
                resp = str2double(resp{1});
                if isnan(resp)
                    errordlg('We weren''t able to parse that into a number. Please try again.','String Parsing Error')
                else
                    edit_details_extracted_details(edit_details_current_field).choices(end+1) = resp;
                end
            else
                edit_details_extracted_details(edit_details_current_field).choices(end+1) = resp;
            end
            edit_details_name_popupmenu_Callback
            set(edit_details_h.details_list,'Value',length(edit_details_extracted_details(edit_details_current_field).choices))
        end
    end
    function edit_details_assign_Callback(varargin)
        sel_tr = h.trial_listbox.getSelectedItems();
        sel_val = get(edit_details_h.details_list,'Value');
        if sel_val > length(edit_details_extracted_details(edit_details_current_field).choices) + 1
            return
        end
        if sel_val > length(edit_details_extracted_details(edit_details_current_field).choices)
            remove_field = true;
        else
            remove_field = false;
        end

        if remove_field
            [o, wasmodified, fieldchange] = set_trial_detail(o,sel_tr,edit_details_extracted_details(edit_details_current_field).name,NaN);
        elseif edit_details_extracted_details(edit_details_current_field).numeric
            [o, wasmodified, fieldchange] = set_trial_detail(o,sel_tr,edit_details_extracted_details(edit_details_current_field).name,edit_details_extracted_details(edit_details_current_field).choices(sel_val));
        else
            [o, wasmodified, fieldchange] = set_trial_detail(o,sel_tr,edit_details_extracted_details(edit_details_current_field).name,edit_details_extracted_details(edit_details_current_field).choices{sel_val});
        end

        if wasmodified
            unsave
            if fieldchange || remove_field
                load_trial_listbox
                if ~remove_field
                    h.trial_listbox.add_column(edit_details_extracted_details(edit_details_current_field).name)
                end
            else
                update_trial_listbox
            end
        end
    end
    %% ---------------------------------------------------------------------------------------------

    function debug_stopper(varargin)
    end

    function flash_in_status_bar(str)
        set(h.trialname_text,'String',str)
        stop(replace_trialname_text)
        start(replace_trialname_text)
    end

    function stop_timer
        stop(replace_trialname_text)
        %set(replace_trialname_text,'TimerFcn',[])
    end

%{
    function setLRDragPtr(varargin)
        set(h.fig,'Pointer', 'custom', 'PointerShapeCData', [NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,2,2,NaN,NaN,NaN,NaN,2,2,NaN,NaN,NaN,NaN;NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN;NaN,NaN,2,1,1,2,NaN,NaN,NaN,NaN,2,1,1,2,NaN,NaN;NaN,2,1,1,1,2,2,2,2,2,2,1,1,1,2,NaN;2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2;NaN,2,1,1,1,2,2,2,2,2,2,1,1,1,2,NaN;NaN,NaN,2,1,1,2,NaN,NaN,NaN,NaN,2,1,1,2,NaN,NaN;NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN;NaN,NaN,NaN,NaN,2,2,NaN,NaN,NaN,NaN,2,2,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN], 'PointerShapeHotSpot',[8,8]);
    end
    function setUDDragPtr(varargin)
        set(h.fig,'Pointer', 'custom', 'PointerShapeCData', [NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,2,1,1,1,2,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,2,1,1,1,1,1,2,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,2,1,1,1,1,1,1,1,2,NaN,NaN,NaN,NaN;NaN,NaN,NaN,2,2,2,2,1,2,2,2,2,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,2,2,2,2,1,2,2,2,2,NaN,NaN,NaN,NaN;NaN,NaN,NaN,2,1,1,1,1,1,1,1,2,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,2,1,1,1,1,1,2,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,2,1,1,1,2,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN], 'PointerShapeHotSpot',[8,8]);
    end
    function setNormalPtr(varargin)
        set(h.fig,'Pointer', 'arrow')
    end
%}
    function h = make_figure()
        % --- FIGURE -------------------------------------
        h.fig = figure( 'Name', ['Olfactometry ' VERSION], ...
            'Tag', mfilename('fullpath'), 'Userdata', @reentry, ...
            'Units', 'pixels', 'ResizeFcn', @resize_window,...
            'MenuBar', 'none', 'DockControls','off',...
            'BusyAction', 'cancel',...
            'HandleVisibility','off','NumberTitle', 'off', ...
            'CloseRequestFcn',@CloseMenuItem_Callback,...
            'Color', get(0,'DefaultUicontrolBackgroundColor'));

        iptPointerManager(h.fig)

        h.FileMenu = uimenu('Parent', h.fig, 'Label', '&File');
        uimenu(	'Parent', h.FileMenu, 'Label', '&New', 'Accelerator', 'n', 'Callback', @NewMenuItem_Callback);
        uimenu(	'Parent', h.FileMenu, 'Label', '&Open...', 'Accelerator', 'o', 'Callback', @OpenMenuItem_Callback);
        uimenu(	'Parent', h.FileMenu, 'Label', '&Save', 'Accelerator', 's', 'Callback', @SaveMenuItem_Callback);
        uimenu(	'Parent', h.FileMenu, 'Label', 'Save &As...', 'Callback', @SaveAsMenuItem_Callback);
        uimenu(	'Parent', h.FileMenu, 'Label', '&Load from workspace', 'Accelerator', 'l', 'Callback', @LoadFromWorkspaceMenuItem_Callback);
        uimenu(	'Parent', h.FileMenu, 'Label', 'Save to &workspace', 'Accelerator', 'w', 'Callback', @SaveToWorkspaceMenuItem_Callback);
        uimenu(	'Parent', h.FileMenu, 'Label', 'E&xit', 'Accelerator', 'q', 'Separator','on', 'Callback', @CloseMenuItem_Callback);

        h.ImportMenuItem = uimenu('Parent', h.fig, 'Label', '&Import', 'Callback', @ImportMenu_Callback);

        h.viewMenu = uimenu(h.fig, 'Label', '&View');
        uimenu(h.viewMenu, 'Label', 'Refresh &trial listbox', 'Callback', @update_trial_listbox)
        uimenu(h.viewMenu, 'Label', 'Reload e&xtensions', 'Callback', @load_extensions)
        uimenu(h.viewMenu, 'Label', 'Reset &figure positions', 'Callback', @reset_gui_positions)
        uimenu(h.viewMenu, 'Label', 'Redraw current view', 'Callback', @redraw_view, 'Accelerator', 'r')
        uimenu(h.viewMenu, 'Label', 'Extract current plot', 'Callback', @extract_plot)

        uimenu('Parent', h.fig, 'Label', 'Debug', 'Callback', @debug_stopper);

        % --- PANELS -------------------------------------
        h.leftpanel = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'line');
        h.leftcenteradj = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'none', 'BackgroundColor',get(0,'DefaultUicontrolBackgroundColor')-0.1,'ButtonDownFcn',@edit_panel_sizes_click);
        h.centerpanel = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'line');
        h.centerrightadj = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'none', 'BackgroundColor',get(0,'DefaultUicontrolBackgroundColor')-0.1,'ButtonDownFcn',@edit_panel_sizes_click);
        h.rightupperpanel = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'line');
        h.rightupperloweradj = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'none', 'BackgroundColor',get(0,'DefaultUicontrolBackgroundColor')-0.1,'ButtonDownFcn',@edit_panel_sizes_click);
        h.rightlowerpanel = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'line');

%        iptSetPointerBehavior([h.leftcenteradj h.centerrightadj],struct('enterFcn',@setLRDragPtr,'traverseFcn',[],'exitFcn',@setNormalPtr))
%        iptSetPointerBehavior(h.rightupperloweradj,struct('enterFcn',@setUDDragPtr,'traverseFcn',[],'exitFcn',@setNormalPtr))


        % --- STATUS BAR -------------------------------------
        h.statusbar = uipanel( h.fig, 'Units', 'pixels', 'BorderType', 'etchedin');

        h.trialname_text = uicontrol(	'Parent', h.statusbar, 'Style', 'text', ...
            'Units', 'pixels', 'HorizontalAlignment', 'left');

        h.statusaxis = axes( 'Parent', h.statusbar, ...
            'Units','pixels', 'Box','on',...
            'Color','none', 'XLim', [0 1], 'XTick', [], 'YLim', [0 1], 'YTick', []);

%         h.statuswait = patch([0 0 0 0],[0 0 1
%         1],'r','EraseMode','none','Parent',h.statusaxis); %tcr patch erasemode no longer supported
        h.statuswait = patch([0 0 0 0],[0 0 1 1],'r','Parent',h.statusaxis);

        % --- AXES -------------------------------------
        h.mainaxes = axes(	'Parent', h.centerpanel, 'Units', 'pixels', ...
            'Box', 'on', 'NextPlot', 'add', 'YTick', [], 'Layer', 'top', 'ButtonDownFcn', @mainaxes_click);

        function mainaxes_click(varargin)
            fire_event('mainaxes_click')
        end

        % --- PUSHBUTTONS -------------------------------------
        h.next_trial = uicontrol(	'Parent', h.leftpanel, 'Style', 'pushbutton', ...
            'Units', 'pixels', 'Position', [70 12 60 30], ...
            'String', 'Next', 'Callback', @next_trial_Callback);

        h.previous_trial = uicontrol(	'Parent', h.leftpanel, 'Style', 'pushbutton', ...
            'Units', 'pixels', 'Position', [5 12 60 30], ...
            'String', 'Previous', 'Callback', @previous_trial_Callback);

        h.edit_details = uicontrol( 'Parent', h.leftpanel, 'Style', 'togglebutton', ...
            'Units', 'pixels', 'Position', [135 12 120 30], ...
            'String', 'Edit trial details', 'Callback', @edit_details_Callback);

        % --- LISTBOXES -------------------------------------
                h.trial_listbox = listbox(h.leftpanel);
%         h.trial_listbox = uicontrol('Parent',h.leftpanel,'Style','Listbox');
        h.itemmenu = uicontextmenu('Parent',h.fig);
        %        uimenu(h.itemmenu, 'Label', 'Plot', 'Callback', @plot_items);
        %        uimenu(h.itemmenu, 'Label', 'Plot Pseudocolor', 'Callback', @plot_pseudo_items);
        uimenu(h.itemmenu, 'Label', 'Edit comment', 'Callback', @edit_trial_comment);
        uimenu(h.itemmenu, 'Label', 'Delete', 'Callback', @delete_trials_Callback, 'Separator', 'on');


        h.roi_listbox = uicontrol('Parent', h.rightlowerpanel, 'Style', 'listbox', ...
            'Units', 'pixels', 'Min', 0, 'Max', 1000', 'Callback', @roi_listbox_Callback, ...
            'Value', [], 'BackgroundColor', [1 1 1]);
        h.roi_listbox_label = uicontrol('Parent', h.rightlowerpanel, 'Style', 'text', ...
            'Units', 'pixels', 'HorizontalAlignment', 'left', 'String', 'Choose ROIs to display:');
        h.roi_listbox_select_all = uicontrol('Parent', h.rightlowerpanel, 'Style', 'pushbutton', ...
            'Units', 'pixels', 'String', 'Select all', 'Callback', @roi_listbox_select_all_Callback);

        h.extension_checktree = checktree(h.rightupperpanel);
        h.extension_menu = uicontextmenu('Parent',h.fig);

        % --- SLIDERS -------------------------------------
        h.scale_slider = uicontrol(	'Parent', h.centerpanel, 'Style', 'slider', ...
            'Units', 'pixels', 'Value', 0.1, 'Callback', @scale_slider_Callback);
    end

    edit_panel_size_selection = [];
    function edit_panel_sizes_click(varargin)
        switch get(h.fig,'SelectionType')
            case 'normal'
                edit_panel_size_selection = varargin{1};
                set(h.fig, 'WindowButtonMotionFcn', @edit_panel_sizes_drag, ...
                    'WindowButtonUpFcn', @edit_panel_sizes_drag_end);
        end
    end
    function edit_panel_sizes_drag(varargin)
        pt = get(h.fig,{'CurrentPoint','Position'});
        switch edit_panel_size_selection
            case h.leftcenteradj
                prefpos.lrpanels(1) = pt{1}(1) - 2;
            case h.centerrightadj
                prefpos.lrpanels(2) = pt{2}(3) - pt{1}(1) - 2;
            case h.rightupperloweradj
                prefpos.rlpanel = (pt{1}(2)-18) / pt{2}(4);
        end
        resize_window
    end
    function edit_panel_sizes_drag_end(varargin)
        set(h.fig, 'WindowButtonMotionFcn', [], 'WindowButtonUpFcn', [])
        edit_panel_size_selection = [];
    end

    function size_window
        set(h.fig,'Position',prefpos.fig)
        resize_window
    end

    lastgoodpos = false;
    
    function resize_window(varargin)
        if ~exist('h','var')
            return
        end
        figpos = get(h.fig,'Position');
        
        try
            
            pos = getpos(figpos,[0 0 0 1],[0 20 prefpos.lrpanels(1) -19]);
            set(h.leftpanel,'Position',pos)
            set(h.trial_listbox.box,'Position',getpos(pos,[0 0 1 1],[4 52 -6 -54]))

            set(h.leftcenteradj,'Position',getpos(figpos,[0 0 0 1],[prefpos.lrpanels(1) 20 4 -19]))

            pos = getpos(figpos,[0 0 1 1],[prefpos.lrpanels(1)+4 20 -sum(prefpos.lrpanels)-8 -19]);
            set(h.centerpanel,'Position',pos)
            set(h.mainaxes,'Position',getpos(pos,[0 0 1 1],[2 52 -22 -54]))
            set(h.scale_slider,'Position',getpos(pos,[1 0 0 1],[-18 52 16 -54]))

            set(h.centerrightadj,'Position',getpos(figpos,[1 0 0 1],[-prefpos.lrpanels(2)-4 20 4 -19]))

            pos = getpos(figpos,[1 prefpos.rlpanel 0 1-prefpos.rlpanel],[-prefpos.lrpanels(2) 20 prefpos.lrpanels(2) -19]);
            set(h.rightupperpanel,'Position',pos)
            set(h.extension_checktree.box,'Position',getpos(pos,[0 0 1 1],[2 2 -4 -4]))
            set(h.rightupperloweradj,'Position',getpos(figpos,[1 prefpos.rlpanel 0 0],[-prefpos.lrpanels(2) -4+20 prefpos.lrpanels(2) 4]))

            pos = getpos(figpos,[1 0 0 prefpos.rlpanel],[-prefpos.lrpanels(2) 20 prefpos.lrpanels(2) -4]);
            set(h.rightlowerpanel,'Position',pos)
            set(h.roi_listbox,'Position',getpos(pos,[0 0 1 1], [2 23 -4 -38]))
            set(h.roi_listbox_label,'Position',getpos(pos,[0 1 1 0], [1 -13 -2 12]))
            set(h.roi_listbox_select_all,'Position',getpos(pos,[0 0 1 0], [2 2 -4 20]))

            pos = getpos(figpos,[0 0 1 0],[1 1 -2 18]);
            set(h.statusbar,'Position',pos)
            set(h.trialname_text,'Position',getpos(pos,[0 0 1 0],[1 1 -202 12]))
            set(h.statusaxis,'Position',getpos(pos,[1 0 0 0],[-200 3 196 12]))

            lastgoodpos = prefpos;
            lastgoodpos.fig = figpos;
        catch
            if isstruct(lastgoodpos)
                prefpos = lastgoodpos;
            else
                set_gui_positions;
            end
            size_window
        end
    end

    fire_event('after_startup')
    reentry(varargin{:}) %process input arguments after everything's loaded

end

function pos = calculate_popup_position(obj, invertedoffset)
    objpos = getpixelposition(obj, true);
    pos = objpos(1:2) + [invertedoffset(1) objpos(4)-invertedoffset(2)];
end

function pos = getpos(pos, fig_frac, pixel_offset)
    pos = pos([3 4 3 4]) .* fig_frac + pixel_offset;
end

function found = connect_existing_instance(varargin)
    h = findall(0,'Tag',mfilename('fullpath'));
    if ishandle(h)
        reentry_fcn = get(h,'Userdata');
        reentry_fcn(varargin{:})
        found = true;
    else
        found = false;
    end
end
