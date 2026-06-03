# Restart simulation from time 0
restart -force -nowave

# Log ALL signals recursively before running
log -r /*

# Add all signals to wave window
add wave -r /*

# Run simulation to completion
run -all