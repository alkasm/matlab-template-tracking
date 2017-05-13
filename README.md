# File List

README - This file  
smb_tracking.m - Example MATLAB script  
match_template.m - MATLAB function  
track_template.m - MATLAB function  
input/smb_w4-1.mp4 - Example video input  
 
# Project Description

This project was an extension to a template matching project I worked on before to incorporate tracking through video feed. The idea was to use frame-by-frame template matching to locate a template within a video, and to optimize the code by reducing the search area for the template based on the previous position. This code at its heart uses a template matching function that uses a scaled sum of square differences.

Some unique functionalities of this template tracking algorithm:

1. You can specify a `radius` around the prior matched template area to search in.
2. You can specify a `threshold` so that matches can be rejected.
3. You can specify a `growth rate` for `radius` so that if the tracked object leaves the search area, `radius` will grow around the last known position until the template is found again.
4. Instead of using *normalized* sum of square differences, I opted to make my own scaling factor to normalize the SSD. It computes the *maximum possible SSD* the `template` can have with *any* `image` and scales by that, to get a true 0-to-1 scaled SSD unique for each template. That means a 90% match is a 90% match regardless of the `template`.

These scripts and functions were built on MATLAB R2017a. The script uses the computer vision toolbox to input and output video and draw a box around Mario, but this can be removed if a license to the toolbox is not possessed and can be read, output, and drawn using the standard Matlab library. The project idea came from a reddit thread in the [r/computervision](https://reddit.com/r/computervision/) subreddit. You can see my subsequent text-post here: [r/computervision/comments/6aqmbo/template_tracking_super_mario/](https://reddit.com/r/computervision/comments/6aqmbo/template_tracking_super_mario/)

# Example Outputs

[https://youtu.be/zo3U3a4nmyY](https://youtu.be/zo3U3a4nmyY)  
This video shows the output from running `smb_tracking`.  

[https://youtu.be/m99H6oH46E8](https://youtu.be/m99H6oH46E8)  
This video shows how setting a `thresh` and `radius` will dynamically adjust the search area for a `template` by expanding `radius` when no good matches (that is, the scaled SSD is above `thresh`) are found  in the previous search area. The code to generate this video is not included but `track_template` can be easily edited to output the search area of each frame. The included example does, however, use this method.

# Description of .m files

**smb_tracking.m**  *requires match_template.m, track_template.m, CV toolbox*  
An example script which reads the included video input and outputs a video drawing a box around a tracked Mario. 

**track_template.m**  *requires match_template.m*  
A function which takes in an `imgseq` (video) and a `template` (with additional optional inputs) and tracks the `template`. The function runs `match_template` on every frame and outputs match locations for each frame, optionally outputting the computed scaled sum of square difference between each `imgseq` frame and `template` at those match locations.  

**match_template.m**  
A function which takes in an `image` and a `template` (with additional optional inputs) and locates the `template` within the `image`. The function outputs the location of the best match, and optionally outputs the computed scaled sum of square difference between `image` and `template` at those match locations.

Run `help <function name>` for detailed usage instructions, additional input options, output options, class support, and basic examples.


# Contributors
Alexander Reynolds  
  [ar@reynoldsalexander.com](mailto:ar@reynoldsalexander.com)  
  [https://github.com/alkasm](https://github.com/alkasm)
