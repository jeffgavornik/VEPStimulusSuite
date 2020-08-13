classdef experimentalRecordsClass <  singletonClass ...
        & storedPreferenceClass ...
        & classThatThrowsWarnings
    % Class that holds a list of system users and their usage count
    %
    % Holds a message queue for each user that can be written out to a text
    % file for record keeping purposes
    
    events
        UserSelectionChanged
    end
    
    properties (Hidden=true)
        userNames
        messageQueue
        queueIndex
        fid = [];
        currentUser
        guiPopupMenu
    end
    
    properties (Hidden=true,SetAccess=private) % Use gui to manage the object
        hLogTable
        hLogUserMenu
        hLogFileTable
    end
    
    properties (Constant,Hidden=true)
        singletonDesignatorKey = 'userRecordsClass';
        prefFileNameStr = 'userRecordsClass';
        maxQueueSize = 500;
        configWarningID = 'experimentalRecordsClass:configProblems';
        defaultUserName = 'DEFAULT';
        logDirectory = 'ExperimentLogs';
    end
    
    methods (Static)
        
        function showConfigWarning(warnStr)
            ME = MException(experimentalRecordsClass.configWarningID,...
                'Experimental Logging Config Problems');
            handleWarning(ME,true,warnStr);
        end
    end
    
    methods
        
        function obj = experimentalRecordsClass
            if obj.singletonNeedsConstruction
                obj.userNames = containers.Map;
                obj.messageQueue = cell(1,obj.maxQueueSize);
                obj.queueIndex = 1;
                obj.preferencePropertyNames = 'userNames';
                obj.loadSavedPreferences;
                obj.currentUser = obj.defaultUserName;
            end
        end
        
        function delete(obj)
            obj.closeLogFile;
        end
        
        % -----------------------------------------------------------------
        % Methods to manage current user selection
        
        function yesOrNo = isReadyToLog(obj)
            yesOrNo = true;
            yesOrNo = yesOrNo * ~isempty(obj.currentUser);
            yesOrNo = yesOrNo * checkFIDValidity(obj.fid);
        end
        
        function set.currentUser(obj,theUser)
            % Assuming theUser is a char, look to see if the selection has
            % changed.  If not, return.  If so, close the current log file,
            % add theUser to the userNames dictionary if it is not already
            % there, open a log file for the new user and post a
            % notification that the user has changed            
            if ~isa(theUser,'char')
                error('%s.currentUser must be a char');
            end
            if isempty(theUser)
                theUser = obj.defaultUserName;
            end
            if strcmp(obj.currentUser,theUser)
                return; % selection didn't change
            end
            obj.currentUser = theUser;
            obj.closeLogFile;
            if ~isempty(theUser)
                %if ~isKey(obj.userNames,theUser)
                obj.addUser(theUser);
                %end
                obj.openLogFile;
            end
            notify(obj,'UserSelectionChanged');
        end
        
        function wasLogged = logMessage(obj,messageStrings)
            % Save a cell array of message strings (or a single char array)
            % in the message queue.  If the queueu gets full, flush the
            % contents to the log file.
            if ~isa(messageStrings,'cell')
                messageStrings = {messageStrings};
            end
            if isempty(obj.currentUser)
                wasLogged = false;
                for iM = 1:length(messageStrings)
                    fprintf('NOTLOGGED:%s\n',messageStrings{iM});
                end
            else
                for iM = 1:length(messageStrings)
                    msg.timestamp = now;
                    msg.str = messageStrings{iM};
                    obj.messageQueue{obj.queueIndex} = msg;
                    obj.queueIndex = obj.queueIndex + 1;
                    if obj.queueIndex > obj.maxQueueSize
                        obj.flushQueue;
                    end
                end
                wasLogged = true;
            end
        end
        
        function addUser(obj,theUser)
            % Ignore newUsers that aren't
            if obj.userNames.isKey(theUser)
                return;
            end
            % Save the new address and initialize a use counter
            obj.userNames(theUser) = 0;
            obj.savePreferences;
        end
        
        function userWasAdded = addNewUserDialog(obj)
            % Spawn a dialog box that allows a user to enter a new user
            userWasAdded = false;
            if rand > 0.5
                dfltName = 'Joe Science';
            else
                dfltName = 'Jane Science';
            end
            theUser = inputdlg('Enter new user name',...
                'User Records',1,{dfltName});
            if isempty(theUser)
                return;
            end
            theUser = theUser{1};
            if isempty(theUser) || isKey(obj.userNames,theUser)
                return;
            end
            obj.addUser(theUser);
            obj.currentUser = theUser;
            userWasAdded = true;
        end
        
        function removeUser(obj,theUser)
            % Remove a user
            if isKey(obj.userNames,theUser)
                obj.userNames.remove(theUser);
                obj.savePreferences;
            end
            if strcmp(theUser,obj.currentUser)
                obj.closeLogFile;
                obj.currentUser = '';
            end
        end
        
        function removeUserDialog(obj)
            % Spawn a dialog box to remove user records
            [users,useCounts] = obj.getSortedUsers;
            nU = length(users);
            if nU == 0
                return;
            end
            userStrs = cell(1,nU);
            for iA = 1:nU
                userStrs{iA} = sprintf('%s (%i)',users{iA},useCounts(iA));
            end
            [index,OK] = listdlg('PromptString','Select a user to remove:',...
                'SelectionMode','single',...
                'ListString',userStrs);
            if OK
                obj.removeUser(users{index});
            end
        end
        
        function [names,useCounts] = getSortedUsers(obj)
            % Sort user names by use count and return the cell array of
            % strings and matching array of useCounts
            names = obj.userNames.keys;
            useCounts = obj.userNames.values;
            % Don't include default user name
            iDefault = find(strcmp(names,obj.defaultUserName));
            names(iDefault) = [];
            useCounts(iDefault) = [];
            [useCounts,ind] = sort(cell2mat(useCounts),'descend');
            names = names(ind);
        end
        
       function flushQueue(obj)
            % Write contents of message queue to the log file and reset the
            % queue index
            % disp('flushQueue');
            for ii = 1:obj.queueIndex-1
                msg = obj.messageQueue{ii};
                fprintf(obj.fid,'%s:',datestr(msg.timestamp));
                theStr = msg.str;
                [rows,~] = size(theStr);
                for iR = 1:rows
                    fprintf(obj.fid,'%s\n',theStr(iR,:));
                end
            end
            obj.queueIndex = 1;
        end
        
        function getLogTable(obj)
            % Create or raise the log table viewer gui.  This is the method
            % that should be used to view the logs
            
            % Check to see if a log table already exists
            if ~isempty(obj.hLogTable) && ishandle(obj.hLogTable)
                figure(get(obj.hLogTable,'Parent'));
                return;
            end
            
            % Create a new figure
            fh = figure('Toolbar','none');
            set(fh,'MenuBar','none');
            obj.hLogTable = uicontrol(fh,'Style','listbox',...
                'Units','Normalized',...
                'Position',[0.2 0.1 0.7 0.8]);
            
            % Get a list of the names of all users that have logs in the
            % directory and select the one that matches the current user
            userDirs = dir(sprintf('%s/%s/',...
                obj.getPrefDir,obj.logDirectory));
            logNames = {};
            for iD = 1:length(userDirs)
                name = userDirs(iD).name;
                if name(1) ~= '.'
                    logNames{end+1} = name; %#ok<AGROW>
                end
            end
            strIndex = find(strcmp(logNames,obj.currentUser));
            if isempty(strIndex)
                strIndex = 1;
            end
            
            % Setup to select user and log file for viewing
            obj.hLogUserMenu = uicontrol(fh,'Style','popupmenu',...
                'Units','Normalized',...
                'Position',[0.0 0.8 0.2 0.1],...
                'String',logNames,'Value',strIndex,...
                'Callback',@(src,evnt)selectLogTableUser(obj));
            obj.hLogFileTable = uicontrol(fh,'Style','listbox',...
                'Units','Normalized',...
                'Position',[0.02 0.1 0.16 0.7],...
                'Callback',@(src,evnt)selectLogFile(obj));
            obj.selectLogTableUser;
        end
        
        
        
        % -----------------------------------------------------------------
        % Methods that allow the object to control a popupmenu gui handle
        
        function set.guiPopupMenu(obj,hPopupMenu)
            % Only allow guiMenu to point at a popupmenu object
            assignProperty = false;
            if isa(hPopupMenu,'matlab.ui.control.UIControl') && ...
                    strcmp(get(hPopupMenu,'Style'),'popupmenu')
                assignProperty = true;
            end
            if assignProperty
                % Make sure that there isn't an old gui element that is
                % still making callbacks against the object
                
                % Assign the new menu operations
                obj.guiPopupMenu = hPopupMenu;
                set(obj.guiPopupMenu,'Callback',...
                    @(hObject,evnt)guiMenuCallback(obj,hObject));
                obj.updateGUI;
            else
                error('%s.guiMenu must be a uicontrol with style=''popupmenu''',class(obj));
            end
        end
        
        function updateGUI(obj)
            % React to user selection events
            users = obj.getSortedUsers;
            menuStrings = [{'No User Selected'},...
                users,{'New User','Remove a User'}];
            set(obj.guiPopupMenu,'String',menuStrings);
            if strcmp(obj.currentUser,obj.defaultUserName)
                strIndex = 1;
            else
                strIndex = find(strcmp(users,obj.currentUser)) + 1;
            end
            set(obj.guiPopupMenu,'Value',strIndex);
        end
        
        function guiMenuCallback(obj,hObj)
            values = get(hObj,'String');
            selection = values{get(hObj,'Value')};
            switch selection
                case 'No User Selected'
                    obj.currentUser = obj.defaultUserName;
                case 'New User'
                    obj.addNewUserDialog;
                case 'Remove a User'
                    obj.removeUserDialog;
                otherwise
                    obj.currentUser = selection;
            end
            obj.updateGUI;
        end
        
    end
    
    methods (Access=private)
        
          
        function updateUserCount(obj,theUser)
            if isKey(obj.userNames,theUser)
                obj.userNames(theUser) = obj.userNames(theUser) + 1;
                obj.savePreferences;
            end
        end
        
        function fid = getLogFileID(obj)
            % Return the fid after making sure that it is valid
            if ~checkFIDValidity(obj.fid)
                obj.openLogFile;
            end
            fid = obj.fid;
        end
        
        function openLogFile(obj)
            % Open the log file with read/write (append) permissions
            % If the logfile doesn't already exist, increase the use count
            % for the current user            
            logFile = obj.getLogFileName;
            updateCountOnSuccess = exist(logFile,'file') == 0;
            try
                [obj.fid,msg] = fopen(logFile,'a+');
                if obj.fid == -1
                    error('fopen failed with msg %s',msg);
                end
            catch ME
                handleWarning(ME,true,'Experimental log failed to open');
                obj.fid = 2;
                updateCountOnSuccess = false;
            end
            if updateCountOnSuccess
                obj.userNames(obj.currentUser) = obj.userNames(obj.currentUser) + 1;
                obj.dirtyBit = true;
            end
        end
        
        function closeLogFile(obj)
            if checkFIDValidity(obj.fid)
                obj.flushQueue;
                try
                    fclose(obj.fid);
                catch ME
                    handleWarning(ME,false,'Experimental log failed to close');
                end
            end
            obj.fid = [];
        end
        
        function logFileName = getLogFileName(obj,userName)
            % Generate a log file name for the current, or indicated, user
            if nargin < 2
                userName = obj.currentUser;
            end
            if isempty(userName)
                logFileName = '';
            else
                userLogDir = sprintf('%s/%s/%s',...
                    obj.getPrefDir,obj.logDirectory,userName);
                retVal = exist(userLogDir,'dir');
                if retVal ~= 7
                    [success,msg,msgid] = mkdir(userLogDir);
                    if ~success
                        ME = MException(msgid,msg);
                        handleWarning(ME,true,...
                            sprintf('getLogFileName(): failed to make new directory ''%s''',userLogDir));
                        userLogDir = '.';
                    end
                end
                logFileName = sprintf('%s/%s.log',...
                    userLogDir,datestr(now,'yyyy-mm-dd'));
            end
        end
        
        
         function showLogFile(obj,userName,logFileName)
            % Display the selected log file content on the GUI
            
            % Show a copy of the log file for the current user
            if exist('userName','var')==0 || isempty(userName)
                userName = obj.currentUser;
            end
            
            if exist('logFileName','var')==0 || isempty(logFileName)
                logFileName = obj.getLogFileName(userName);
            end
            
            %fprintf('%s userName=%s logFileName=%s\n',...
            %    fncNameStr,userName,logFileName);
            
            useCurrent = strcmp(userName,obj.currentUser) && ...
                strcmp(logFileName,obj.getLogFileName(userName));
            
            try
                % Read the contents of the log file into a cell array where
                % each element of the array is a single line in the log
                % file
                
                if useCurrent
                    obj.flushQueue;
                    FID = obj.getLogFileID;
                    startPos = ftell(FID);
                    % Note: close and reopen file so that it can be read.
                    % This should not be necessary but there is a problem
                    % with textscan in R2014b that prevents read access to
                    % a file opened for read/write
                    fclose(FID);
                    [FID,msg] = fopen(logFileName);
                else
                    [FID,msg] = fopen(logFileName);
                end
                if FID == -1
                    error('fopen failed to open %s with msg %s',logFileName,msg);
                end
                strCell = textscan(FID, '%s', 'delimiter', '\n');
                if useCurrent
                    fclose(FID);
                    [FID,msg] = fopen(logFileName,'a+');
                    if FID == -1
                        error('fopen failed with msg %s',msg);
                    end
                    fseek(FID,startPos,'bof');
                    obj.fid = FID;
                    if ftell(FID)~=startPos
                        error('file position not restored');
                    end
                else
                    fclose(FID);
                end
                % Open a window to show the contents of the log file
                obj.getLogTable;
                set(obj.hLogTable,'String',strCell{:});
                set(get(obj.hLogTable,'Parent'),'Name',logFileName);
                %strCell = dataread('file',logFileName,'%s','delimiter','\n');
            catch ME
                handleWarning(ME,true,'showLogFile failure');
            end
            
        end
        
        function selectLogTableUser(obj)
            logUserNames = obj.hLogUserMenu.String;
            logUsername = logUserNames{obj.hLogUserMenu.Value};
            logFiles = dir(sprintf('%s/%s/%s/*.log',...
                obj.getPrefDir,obj.logDirectory,logUsername));
            logNames = cell(1,length(logFiles));
            for iF = 1:length(logFiles)
                logNames{iF} = logFiles(iF).name;
            end
            if isempty(logNames)
                logNames = {'No log files'};
            end
            obj.hLogFileTable.String = logNames;
            obj.hLogFileTable.Value = length(logNames);
            obj.selectLogFile;
        end
        
        function selectLogFile(obj)
            logName = obj.hLogFileTable.String{obj.hLogFileTable.Value};
            logUserName = obj.hLogUserMenu.String{obj.hLogUserMenu.Value};
            obj.showLogFile(logUserName,fullfile(obj.getPrefDir,...
                obj.logDirectory,logUserName,logName));
        end
        
    end
    
end