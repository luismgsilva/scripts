import sys
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

#text_file_path = sys.argv[1]
#attachment_path = sys.argv[2]
#with open(text_file_path, "r") as file:
#  email_body = file.read()

#subject = "Email Subject"
#body = "This is the body of the text message"
#body = email_body
#sender = "bsf.ci.noreply@gmail.com"
#recipients = ["luiss@synopsys.com", "luis.m.silva99@hotmail.com", "linun77@gmail.com"]
#cc_recipients = ["luiss@synopsys.com"]
#password = "xvscfirnoipabpff"


def send_email(subject, body, sender, recipients, cc_recipients, password, attachment_path = None):
    #msg = MIMEText(body, "plain")
    msg = MIMEMultipart("alternative")
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = ', '.join(recipients)
    msg['Cc'] = ', '.join(cc_recipients)

    plain_text = "ai"
    msg.attach(MIMEText(plain_text, "plain"))
    msg.attach(MIMEText(body, "html"))

    if attachment_path:
      with open(attachment_path, "rb") as attachment_file:
        attachment = MIMEApplication(attachment_file.read())
        attachment.add_header("Content-Disposition", "attachment", filename=attachment_path)
        msg.attach(attachment)

    with smtplib.SMTP_SSL('localhost', 2525) as smtp_server:
      smtp_server.login(sender, password)
      all_recipients = recipients + cc_recipients
      smtp_server.sendmail(sender, all_recipients, msg.as_string())
    print("Message sent!")


#send_email(subject, body, sender, recipients, password, attachment_path)



def help():
	print("""
Usage: python3 <script_name.py> <recipient1,recipient2,...> [options...]

Global options:
  -h  | --help        Print usage and exit
  -cc | --carbon-copy                Specify address to send a copy to.
									 Multiple addresses can be supplied using a comman ","
  -s  | --subjet                     Specify subject to email.
  -f | --html-body-file				 Specify a html body file path.
""")
	sys.exit()


def get_password():
	with open("/home/luiss/.email_pass", "r") as file:
		password = file.read()
	return password.strip()

def get_file(file_path):
	with open(file_path, "r") as file:
		email_body = file.read()
	return email_body

def set_defaults(options):

	options["subject"]	 = "Email Subject"
	options["body"]		 = "This is the body of the text message"
	options["sender"]	 = "bsf.ci.noreply@gmail.com"
	options["cc_recipients"] = ["luiss@synopsys.com"]
	options["password"] = get_password()

	return options


def option_parser(argv):
	
	options = {}
	options = set_defaults(options)
	options["recipients"] = argv[1].split(",")
	
	while argv:
		option = argv.pop(0)
		if option in ["-h", "--help"]:
			help()
		elif option in ["-cc", "--carbon-copy"]:
			options["cc_recipients"].add(argv.pop(0).split(","))
		elif option in ["-s", "--subject"]:
			options["subject"] = argv.pop(0)
		elif option in ["-f", "--body-file"]:
			options["body"] = get_file(argv.pop(0))


	return options


def error(msg):
	print(msg)
	sys.exit(1)

def main():
	if len(sys.argv) < 2:
		help()

	options = option_parser(sys.argv)
	
	subject    = options["subject"]
	body       = options["body"]
	sender     = options["sender"]
	recipients = options["recipients"]
	cc_recipients = options["cc_recipients"]
	password   = options["password"]

	if not options["recipients"]:
		error("error: Recipients not found")
	
	print(options)
	send_email(subject, body, sender, recipients, cc_recipients, password)


if __name__ == "__main__":
	main()
