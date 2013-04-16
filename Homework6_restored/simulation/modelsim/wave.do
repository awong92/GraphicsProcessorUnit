view wave 
wave clipboard store
wave create -pattern none -portmode input -language vlog /lg_highlevel/CLOCK_50 
wave modify -driver freeze -pattern clock -initialvalue St1 -period 20ns -dutycycle 50 -starttime 0ns -endtime 50000ns Edit:/lg_highlevel/CLOCK_50 

add wave -position insertpoint sim:/lg_highlevel/Fetch0/*
add wave -position insertpoint sim:/lg_highlevel/Decode0/*


WaveCollapseAll -1
wave clipboard restore
