classdef messageEventData < event.EventData
    % Subclass of event.EventData used to specify notification messages by
    % ScrnCtrlApp.m
    
    properties
        subject
        text
    end
    methods
        function obj = messageEventData(subject,text)
            obj.subject = subject;
            obj.text = text;
        end
    end
end