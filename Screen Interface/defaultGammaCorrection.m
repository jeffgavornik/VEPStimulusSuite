function gammaPrefs = defaultGammaCorrection
% Return a default, uncalibrated gamma correction preference structure
gammaPrefs = struct;
gammaPrefs.gamma = 1;
sio = screenInterfaceClass;
gammaPrefs.blackSetPoint = sio.black;
gammaPrefs.whiteSetPoint = sio.white;
