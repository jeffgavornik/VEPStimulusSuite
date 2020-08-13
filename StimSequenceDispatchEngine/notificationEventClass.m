classdef notificationEventClass < event.EventData
    % Used to send notification data containing a description of the
    % triggering event
   
    properties
        descStr
    end
    
    methods
       
        function obj = notificationEventClass(descriptionString)
            obj.descStr  = descriptionString;
        end
        
    end
    
end