#! /usr/local/bin/ruby
utfroot=File.dirname(File.expand_path(__FILE__))



ENV["UTFROOT"]=utfroot
ENV["UTFGLOBALFILE"]=utfroot+"/conf/_global.conf"
ENV["LOGFILE"]=utfroot+"/log/test.log"
ENV["EMAILBODYDIR"]="./conf/emailbody"



$LOAD_PATH << ENV["UTFROOT"]+"/lib"

load "log.rb"
load "utf.rb"

ENV["LOGLEVEL"]="verbose"
#ENV["LOGLEVEL"]="basic"
 
testscript="#{utfroot}/conf/schedule.csv"
  
 
TC.run(testscript)

cmd="crontab -l"
consoleOutPut,cmdExitCode = UTF.cmdlocal(cmd)
puts "\n\nSYSTEM CRON LIST:"
puts consoleOutPut
 
 