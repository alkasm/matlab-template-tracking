# File List
README - This file  
smb_tracking.m - Example MATLAB script  
match_template.m - MATLAB function  
track_template.m - MATLAB function  
input/smb_w4-1.mp4 - Example video input  
 
# Project Description
These scripts and functions were built on MATLAB R2017a. The script 
requires the computer vision toolbox only to draw a box around Mario,
but this can be removed if a license to the toolbox is not possessed.
The project idea came from a reddit thread, which can be found here: 
[https://reddit.com/r/computervision/comments/69p1bj/](https://reddit.com/r/computervision/comments/69p1bj/)

# Example Outputs
[https://youtube...](https://youtube.com/...)  
  This video shows the output from running smb_tracking.m.  
[https://youtube...](https://youtube.com/...)  
  This video shows how setting a THRESH and RADIUS will dynamically
  adjust the search area for a TEMPLATE by expanding RADIUS when
  no good matches (that is, the scaled SSD is above THRESH) are found 
  in the previous search area. The code to generate this video is not
  included but track_template.m can be easily edited to output the 
  search area of each frame. The included example does, however, use
  this method.

# Description of .m files
**smb_tracking.m**  *requires match_template.m, track_template.m, CV toolbox*  
  An example script which reads the included video input and outputs
  a video drawing a box around a tracked Mario.
**track_template.m**  *requires match_template.m*  
  A function which takes in an image sequence (video) and a template
  (with additional optional inputs) and tracks the template. The 
  function runs MATCH_TEMPLATE on every frame and outputs match
  locations for each frame, and optionally outputs the computed
  scaled sum of square difference between IMAGE and TEMPLATE at 
  those match locations.
**match_template.m**  
  A function which takes in an IMAGE and a TEMPLATE (with additional 
  optional inputs) and locates the TEMPLATE within the IMAGE. The 
  function outputs the location of the best match, and optionally 
  outputs the computed scaled sum of square difference between IMAGE 
  and TEMPLATE at those match locations.

Run `help <function name>` for detailed usage instructions, additional
input options, output options, class support, and basic examples.


# Contributors
Alexander Reynolds  
  [ar@reynoldsalexander.com](mailto:ar@reynoldsalexander.com)  
  [https://github.com/alkasm](https://github.com/alkasm)
