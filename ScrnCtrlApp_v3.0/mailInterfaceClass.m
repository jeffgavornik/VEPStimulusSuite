classdef mailInterfaceClass <  singletonClass & storedPreferenceClass
    % Class that support sending emails from within the StimulusSuite
    % environment.  Uses the BearLabBot gmail account.
    
    properties (Hidden=true,Access=private)
        account = 'BearLabBot@gmail.com';
        password = 'firman01';
    end
    
    properties (Hidden=true)
        % savedAddresses is a containers.Map.  Keys are the addresses,
        % values are use counts that increment by 1 each time an email is
        % sent to that address.  This variable is automatically saved in
        % the preference file.
        savedAddresses
        sendto
    end
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'mailInterfaceClass';
    end
    
    methods
        
        function obj = mailInterfaceClass
            if obj.singletonNeedsConstruction
                % Set up Gmail SMTP service
                setpref('Internet','E_mail',obj.account);
                setpref('Internet','SMTP_Server','smtp.gmail.com');
                setpref('Internet','SMTP_Username',obj.account);
                setpref('Internet','SMTP_Password',obj.password);
                props = java.lang.System.getProperties;
                props.setProperty('mail.smtp.auth','true');
                props.setProperty('mail.smtp.socketFactory.class',...
                    'javax.net.ssl.SSLSocketFactory');
                props.setProperty('mail.smtp.socketFactory.port','465');
                obj.sendto = [];
                obj.savedAddresses = containers.Map;
                obj.preferencePropertyNames = 'savedAddresses';
                obj.loadSavedPreferences;
            end
        end
        
        function setTargetAddress(obj,theAddress)
            if ~isempty(theAddress) && ~isKey(obj.savedAddresses,theAddress)
                obj.saveAddress(theAddress);
            end
            obj.sendto = theAddress;
        end
        
        function theAddress = getTargetAddress(obj)
            theAddress = obj.sendto;
        end
        
        function sendMail(obj,message)
            % message should be a string or messageEventData object
            try
                if isempty(obj.sendto)
                    error('Empty sendTo field');
                end
                if isa(message,'char')
                    subject = 'Mail Daemon Message';
                    text = message;
                else
                    subject = message.subject;
                    text = message.text;
                end
                sendmail(obj.sendto,subject,text);
                obj.savedAddresses(obj.sendto) = ...
                    obj.savedAddresses(obj.sendto)+1; % use count
            catch ME
                handleWarning(ME,true,...
                    'mailInterfaceClass: sendMail failure')
            end
        end
        
        function saveAddress(obj,theAddress)            
            % Ignore newAddress that isn't
            if obj.isKey(theAddress)
                return;
            end
            % Save the new address and initialize a use counter
            obj.savedAddresses(theAddress) = 0;
            obj.savePreferences;
        end
        
        function addressWasAdded = addNewAddressDialog(obj)
            % Spawn a dialog box that allows a user to enter a new email
            % address
            addressWasAdded = false;
            theAddress = inputdlg('Enter new email address',...
                'E-mail interface',1,{'something@somewhere'});
            if isempty(theAddress) 
                return;
            end
            theAddress = theAddress{1};
            if isKey(obj.savedAddresses,theAddress)
                return;
            end
            obj.saveAddress(theAddress);
            obj.setTargetAddress(theAddress);
            addressWasAdded = true;
        end
        
        function removeAddress(obj,theAddress)
            % Remove an address and its use counter
            if isKey(obj.savedAddresses,theAddress)
                obj.savedAddresses.remove(theAddress);
                obj.savePreferences;
                if strcmp(theAddress,obj.sendto)
                    obj.sendto = [];
                end
            end
        end
        
        function removeAddressDialog(obj)
            [addresses,useCounts] = obj.getSortedAddresses;
            nA = length(addresses);
            if nA == 0
              return;
            end
            addressStrs = cell(1,nA);
            for iA = 1:nA
                addressStrs{iA} = sprintf('%s (%i)',addresses{iA},useCounts(iA));
            end
            [index,OK] = listdlg('PromptString','Select an address to remove:',...
                'SelectionMode','single',...
                'ListString',addressStrs);
            if OK
                obj.removeAddress(addresses{index});
            end
        end
        
        function [addresses,useCounts] = getSortedAddresses(obj)
            % Sort addresses by use count and return the cell array of
            % strings and matching array of useCounts
            addresses = obj.savedAddresses.keys;
            useCounts = obj.savedAddresses.values;
            [useCounts,ind] = sort(cell2mat(useCounts),'descend');
            addresses = addresses(ind);
        end
        
    end
    
end