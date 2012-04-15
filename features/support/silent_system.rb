def silent_system(cmd)
#  silent_cmd = cmd + " 2>&1 > /dev/null"
  silent_cmd = cmd 
  system(silent_cmd)
end
