# avr-toolchain-updated-buildscript
 
 
 This script are modified versions of the original avr-toolchain script used by Arduino. I modified it to cache downloads and extracted archives for reduced build times. I also added command support as good as I could. But everything is still extremely crude.
 
Disclaimer: This script is not really reliable. Since I do not know much of Bash, please feel free to suggest corrections when you see face-palming code.

I was often (un-) commenting some lines when building so you might have to play around a bit.

Things were buildable in a Ubuntu x64 Virtual Machine for 64-bit Windows and Linux. 32-bit Windows always failed because of redefinitions.