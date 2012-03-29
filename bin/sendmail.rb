#!/usr/bin/ruby

froot=File.dirname(File.expand_path(__FILE__))
utfroot=froot+"/../"
ENV["UTFROOT"]=utfroot
ENV["UTFGLOBALFILE"]=utfroot+"/conf/_global.conf"



$LOAD_PATH << ENV["UTFROOT"]+"/lib"
require 'net/smtp'
load "utf.rb"
load "tc.rb"
require 'yaml'
require 'optparse'



TC.loadGlobal()

smtpSrv=Parseconf.translateOneCMD('#{SMTP_SRV}')
authUsr=Parseconf.translateOneCMD('#{AUTH_USR}')
authPwd=Parseconf.translateOneCMD('#{AUTH_PWD}')
domain=Parseconf.translateOneCMD('#{DOMAIN}')


#---- get cli specified configuration file.
 options = {}
 optparse = OptionParser.new do|opts|
     opts.on( '-h', '--help', 'Display this screen' ) {  puts opts; exit }
     opts.on( '-c', '--conf config_file', "configration yaml file"  ){|conf|  options[:conf] = conf }
     end
 optparse.parse!
 
 
#---- parse configuration file 
if !options[:conf].nil?
  options[:to]=options[:cc]=options[:bcc]=options[:replyTo]=[]
  options[:subject]=options[:body]=""
  options[:importance]="normal"
  options[:login]=false
  
  yml = YAML::load(File.open(options[:conf]))
  options[:from] = yml["header"]["from"]
  options[:to] = yml["header"]["to"]
  options[:cc]=  yml["header"]["cc"]
  options[:bcc]= yml["header"]["bcc"]
  options[:replyTo]= Parseconf.translateOneCMD(yml["header"]["replyTo"])
  options[:subject]= yml["header"]["subject"]
  options[:importance]= yml["header"]["importance"]
  options[:body]= yml["emailbody"]
  options[:login]= yml["loginsmtp"]
  options[:attachment]= yml["attachment"]

  options.each{|key,value| options[key]=Parseconf.translateOneCMD(value)}
  
end #if optoins[:conf]


#---- Send email
toList=ccList=bccList=replyList=[]
from=options[:from]
toList=options[:to].split(" ") if !options[:to].nil?
ccList=options[:cc].split(" ") if !options[:cc].nil?
bccList=options[:bcc].split(" ") if !options[:bcc].nil?
replyList=options[:replyTo].split(" ") if !options[:replyTo].nil?
importance=options[:importance]
subject=options[:subject]
body=options[:body]
attachment=options[:attachment]



if (toList.empty? and ccList.empty? and bccList.empty?)
  puts "at least specify one email address at --to,--cc,or --bcc"
  exit
end



subject="" if subject.nil?
toStr=ccStr=bccStr=""
toStr=toList.join(";") if !toList.empty?
ccStr=ccList.join(";") if !ccList.empty?
bccStr=bccList.join(";") if !bccList.empty?
replyToStr=replyList.join(";") if !replyList.empty?

marker = "AUNIQUEMARKER"
msgHeader=msgBody=msgAttach=""

msgHeader=<<EOF
To: #{toStr}
CC: #{ccStr}
BCC:#{bccStr}
Subject: #{subject}
Importance: #{importance}
MIME-Version: 1.0
EOF

if !attachment.nil?
  msgHeader+="Content-type: multipart/mixed; boundary=#{marker}\n--#{marker}\n"
end

#8bit

# Define the message action
msgBody =<<EOF
Content-Type: text/html
Content-Transfer-Encoding:8bit

#{body}
EOF

if !attachment.nil?
  msgBody +="--#{marker}\n"
end
# Define the attachment section

if !attachment.nil?
  filename = attachment
  filebasename=File.basename(filename)
  filetype = `file --mime #{filename}`
  filetype = filetype.split(": ")[1].split(";")[0]
  filetype=filetype.chomp
  
  # Read a file and encode it into base64 format
  filecontent = open(filename, "rb") {|io| io.read }
  filecontent1 = File.read(filename)

  encodedcontent=filecontent
  

  encodedcontent = [filecontent].pack("m")   # base64
  
msgAttach =<<EOF
Content-Type: #{filetype}\;name="#{filebasename}"
Content-Transfer-Encoding:base64
Content-Disposition: attachment;filename="#{filebasename}"

#{encodedcontent}
--#{marker}--
EOF
end #if !attachment.nil?

sendBody = msgHeader + msgBody + msgAttach

sendList = toList+ccList+bccList




begin

if options[:login]
  #login version. The sender will be in recognized format in outlook.
  if authUsr == "AUTH_USR"
    puts 'not found AUTH_USR in _global.conf while case required login smtp server.';exit    
  end
  
  if authPwd == "AUTH_PWD"
    puts 'not found AUTH_PWD in _global.conf while case required login smtp server.'; exit
  end
  
  smtp=Net::SMTP.start(smtpSrv,25,domain,authUsr,authPwd,:login)
  sendBody.gsub!(/@mail.corp.abc.com/,"@abc.com")
  from.gsub!(/@mail.corp.abc.com/,"@abc.com")
  sendList.each{|x|x.gsub!(/@mail.corp.abc.com/,"@abc.com")}
  
else
  #anonymous send email.The sender will not be in recognized formation in outlook. 
  smtp=Net::SMTP.start(smtpSrv,25)
  sendBody.gsub!(/@abc.com/,"@mail.corp.abc.com")
  from.gsub!(/@abc.com/,"@mail.corp.abc.com")
  sendList.each{|x|x.gsub!(/@abc.com/,"@mail.corp.abc.com")}
end



smtp.send_message sendBody,from,sendList
smtp.finish
puts "email sent, subject:"+subject+",sent to:"+sendList.join(";")
rescue Exception => e 
    puts "err when send email:\n" + e
end

