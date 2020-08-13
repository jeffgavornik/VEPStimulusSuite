classdef singletonClass < handle
    % Define a class that allows for only a single instance to exist at a
    % time.  Stores the singleton object handle in a dictionary accessed
    % via get(0,'UserData')
    % 
    % All calls to the constructor subclassess will return the same object.
    %
    % Subclass constructors should initialize variables only if the
    % singletonNeedsConstruction flag is true because subclass constructors
    % are still invoked even when an existing object is being returned.
    % Note that this flag is  true when a new object is being created,
    % and false when an existing object is being returned.  Example:
    %     function obj = singletonSubclassObject()
    %         if obj.singletonNeedsConstruction
    %           someProperty = initialValue;
    %         end
    %     end
    %
    % Note: when the constructor is called for a singleton class that has
    % already been instantiated, an empty object is created that is
    % immediately destroyed.  This means that singleclass destructors
    % should test the isConstructed flag before performing any actions that
    % will effect the existing object or thrown an error when performed on
    % an uninitialized property.  Example:
    %     function delete(obj)
    %         if obj.isConstructed
    %             obj.someObj.someMethod;
    %         end
    %     end
    
    properties (Access=private)
        singletonDesignationKey
    end
    
    properties (Hidden=true)
        isConstructed = false;
        singletonNeedsConstruction = true;
    end
    
    methods (Static)
        
        function deleteAll
            % This will delete all objects stored in userdata that are
            % subclasses of singletonClass
            userData = get(0,'UserData');
            keys = userData.keys;
            for iK = 1:length(keys)
                try %#ok<TRYNC>
                    obj = userData(keys{iK});
                    scs = superclasses(obj);
                    if sum(strcmp(scs,'singletonClass'))
                        delete(obj);
                    end
                end
            end
        end
        
    end
    
    methods
        
        function hObj = singletonClass(varargin)
            % This method will execute before subclass constructor
            if ~hObj.isConstructed
                hObj.singletonDesignationKey = ...
                    sprintf('%s_singletonClass',class(hObj));
            end
            hObj = hObj.returnObject();
            hObj.isConstructed = true;
        end
        
         function delete(obj)
             % This will execute at the end of any subclass override of
             % delete()
             if obj.isConstructed && obj.checkForExisting
                 obj.removeFromUserData();
             end
         end
         
    end
    
    methods (Access=private)
        
        function obj = returnObject(obj)
            % If there is already an object of the class in the user data, 
            % return it.  Otherwise add the passed object to the user data
            % and return it.
            if obj.checkForExisting
                userData = get(0,'UserData');
                obj = userData(obj.singletonDesignationKey);
                obj.singletonNeedsConstruction = false;
            else
                obj.addToUserData();
            end
        end
        
        function removeFromUserData(obj)
            % Remove existing instance of the object from the userData
            userData = get(0,'UserData');
            if isa(userData,'containers.Map') && ...
                    isvalid(userData)
                if userData.isKey(obj.singletonDesignationKey)
                    fprintf('singletonClass: removing %s from userData\n',class(obj));
                    userData.remove(obj.singletonDesignationKey);
                end
            end
        end
        
        function addToUserData(obj)
            % Add an instance of the object class to the userData
            userData = get(0,'UserData');
            if ~isa(userData,'containers.Map')
                userData = containers.Map;
            end
            userData(obj.singletonDesignationKey) = obj;
            set(0,'UserData',userData)
        end
        
        function exists = checkForExisting(obj)
            % Look to see if an instance of the object class exists in the
            % user data
            exists = false;
            userData = get(0,'UserData');
            if isa(userData,'containers.Map') && ...
                    isvalid(userData)
                if userData.isKey(obj.singletonDesignationKey)
                    exists = true;
                end
            end
        end
        
    end
        
        
    
end