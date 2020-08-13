classdef defaultGaussianMask < gaussianMaskClass & singletonClass & storedPreferenceClass
    % Default 2D gaussian mask.  Automatically saves changes to sigX, sigY,
    % and maskColor
    
    properties (Constant,Hidden=true)
        prefFileNameStr = 'defaultGaussianMask.mat';
    end
    
    methods
        
        function obj = defaultGaussianMask
            obj.preferencePropertyNames = {'sigX' 'sigY' 'maskColor'};
            obj.loadSavedPreferences;
            obj.listenForPreferenceChanges;
        end
        
    end
    
end