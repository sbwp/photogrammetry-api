# Photogrammetry API

This web API allows you to generate 3D objects as a USDZ file from HEIC photos. It only runs on macOS, as it uses Apple's Object Capture photogrammetry API.

## Setup
1. Install vapor using Homebrew if you don't have it: `brew install vapor`
2. Open the project in Xcode
3. In the top bar area of Xcode, click on the name of the application and choose Edit Schemes...
4. For the Run scheme, in the Arguments tab, add the argument `serve --hostname 0.0.0.0 --port 8080 --log trace`
5. In the Options tab, check "Use custom working directory" and provide the path to a directory that exists. The .gitignore allows using a directory named `workingDir` in the project directory. Specify the absolute path, e.g. `/Users/john/Developer/photogrammetry-api/workingDir`
    - Note: I haven't checked, but this may not be used anymore <!-- TODO: Remove this item if this is the case -->
6. Click the Run button in Xcode to start the API
7. Install [the companion iOS app](https://github.com/sbwp/photogrammetry-app) on an iPhone with depth cameras
