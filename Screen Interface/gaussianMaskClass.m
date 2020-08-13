classdef gaussianMaskClass < alphaMaskClass
    % 2D gaussian mask
    
    properties (SetObservable,AbortSet)
        % Standard deviation of gaussian mask, in pixels
        sigX = 360;
        sigY = 360;
        maskColor = 'gray';
    end
    
    methods
        
        function obj = gaussianMaskClass
            obj.makeMask;
        end
        
        function set.sigX(obj,value)
            obj.sigX = value;
            obj.makeMask;
        end
        
        function set.sigY(obj,value)
            obj.sigY = value;
            obj.makeMask;
        end
        
        function set.maskColor(obj,colorString)
            if ~sum(strcmpi({'white','black','gray'},colorString))
                error('maskColor is either ''white'',''black'', or ''gray''');
            end
            obj.maskColor = lower(colorString);
            obj.makeMask;
        end
        
        function makeMask(obj)
            sio = screenInterfaceClass.returnInterface;
            res = sio.getScreenResolution;
            cols = res.width;
            rows = res.height;
            [x,y]=meshgrid(-cols/2:cols/2-1, -rows/2:rows/2-1);
            switch obj.maskColor
                case 'white'
                    fgColor = sio.white;
                case 'black'
                    fgColor = sio.black;
                otherwise
                    fgColor = sio.gray;
            end
            obj.maskMatrix=ones(rows, cols, 2) * fgColor;
            obj.maskMatrix(:,:,2) = sio.white-exp(-((x/obj.sigX).^2)-...
                ((y/obj.sigY)).^2)*sio.white;            
        end
        
        function showMask(obj)
            sio = screenInterfaceClass.returnInterface();
            if ~sio.verifyWindow
                sio.openScreen;
            end
            if ~sio.alphaBlendingEnabled
                sio.enableAlphaBlending;
            end
            if isempty(obj.masktex)
                obj.makeTexture;
            end
            obj.renderPattern;
            obj.renderMask;
            sio.flipScreen;
        end
        
    end
    
end