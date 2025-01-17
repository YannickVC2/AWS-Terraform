#!/bin/bash

#System updates
sudo apt-get update

#Install curl, git, gnupg, docker, terraform
sudo apt-get install curl git awscli gnupg software-properties-common docker.io mysql-client-core-8.0 -y

#Add official Hashicorp linux repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#Add Hashicorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

#Install Terraform
sudo apt-get update && sudo apt-get install terraform -y

#Install AWSCLI
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

#Git Clone
git clone https://github.com/Yannick-VC/Internship

echo -e "\n====================================="
echo "Your system passed the test!"
echo -e "=====================================\n"

#Configure AWS CLI correct using aws configure
echo "Please enter your AWS access key credentials correctly" 
aws configure

#Username validation
read -r -p "Before continuing, enter your username! (between 3-15 characters) | " player

#If username incorrect length/characters
while :
do
if [[ ${#player} -le 2 || ${#player} -ge 16 ]]; then
echo -e "Given username contains ${#player} character(s), re-enter your username (between 3-15 characters)"
read -r -p "" player
else break
fi
done

#Styling
Blue="\033[01;34m"
Red="\033[01;31m"
Green="\033[01;32m"
MainC="\033[01;37m"
ClearColor="\033[0m"
Bold=$(tput bold)
Normal=$(tput sgr0)

#Playing menu
while :
do
clear
cat<<EOF
=============================================
| Cyber Cloud Internship                    |
|------------------------------------------ |
| Hello, $player, please make a choise:
|                                           |
| Play            (1)                       |
| How to play     (2)                       |
| Credits         (3)                       |
| Quit            (4)                       |
---------------------------------------------
EOF

#All player choices from menu
read -n1 -s
case "$REPLY" in
    "1")echo -e "Welcome ${Bold}$player${Normal}, the scenario will be set up for you. This can take up to 10 minutes so \x0agrab a coffee and wait untill you see the Public_IP output at the bottom!\x0a"

	#cd to correct place
        cd ./Internship/s1/
	rm ../menu.sh

	#Initialize entire scenario
	terraform init
	terraform plan
	terraform apply -auto-approve

	#Creating user with static password 
	aws iam create-user --user-name ad-
	aws iam create-login-profile --user-name ad- --password Funkymonkey123! --no-password-reset-required
	aws iam add-user-to-group --user-name ad- --group-name administrators
	clear
	terraform output

	#Storyline
	echo -e "${Bold}Scenario description${Normal}"
	echo -e "First of all thanks for playing! Lets dive into the scenario."
	echo -e "For this scenario of a couple of high school students, they were tasked to create a production environment. \x0aInside of this environment they created a VM that would act as a web server, a database that was connected to this web server and they\x0aalso made use of user accounts in the AWS console as well as the Backup service for their database.\x0aThese students, however, didn’t have any experience with creation secure environment which resulted in a publicly facing resources, basic  \x0acredentials and poor encryption methods." 
	echo -e "Combining the results of these errors would allow an attacker with malicious intent to take over the entire environment, destroying or misusing its content or take the company hostage."
	echo -e "NOTE: The AWS Region used for this challenge is EU-WEST-3 (Paris)"
	read -n 1 -s -r -p  $'\x0aPress any key to start!\x0a'

	#Fetch vault solution from AWSCLI
	export vaultname=$(aws backup list-backup-vaults --query 'BackupVaultList[1].BackupVaultName')
	temp="${vaultname%\"}"
	finalanswer="${temp#\"}"

	#Game rules
	MAX_TRIES="30"
	TRIES="0"
	REMAINING="30"

	#Q&A
	q1="Question 1: Give the exact endpoint for which the database is hosted. (using the provided public IP)"
	q2="Question 2: What is the password for the PHPMyAdmin login page?"
	q3="Question 3: What is the username of the admin account? (found somewhere in the database)"
	q4="Question 4: What is the decrypted password for this account?"
	q5="Question 5: To what services has this user any rights?"
	q6="Question 6: What is the name for the specific backup vault?"
	a1="/phpmyadmin"
	a2="password123"
	a3="ad-"
	a4="Funkymonkey123!"
	a5="AwsBackUpFullAccess"
	a6=$finalanswer

	#Functions
	destroy() {
		aws iam remove-user-from-group --user-name ad- --group-name administrators
		aws iam delete-login-profile --user-name ad-
		aws iam delete-user --user-name ad-
		terraform destroy -auto-approve
	}

	ask_question() {
		echo "$1"
		read -r -p $'' answer
		while [ $answer != "$2" ]; do
			if [ $REMAINING -le "0" ]; then
				echo "You've gotten to many wrong answers (we might think you're brute forcing the answers). The game will shut down now."
				sleep 5
				destroy
				exit
			else
				TRIES=$(expr $TRIES + 1)
				REMAINING=$(expr $MAX_TRIES - $TRIES)
				echo -e "\x0a${Red}WRONG${ClearColor}, $REMAINING guesse(s) remaining."
				echo "$1"
				read -r -p $'' answer
			fi
		done
		echo -e "${Green}CORRECT!${ClearColor}\x0a"
	}

	#Ask consequential questions
	ask_question "$q1" "$a1"
	ask_question "$q2" "$a2"
	ask_question "$q3" "$a3"
	ask_question "$q4" "$a4"
	ask_question "$q5" "$a5"
	ask_question "$q6" "$a6"

	#End of scenario + destruction
	echo -e "Congratulations, you reached the end! Thank you for playing $player! The scenario will close down and you will be redirected to the main menu.\x0aThis may take some time so sit back and grab a coffee!"
	sleep 10
	destroy
	;;
    "2")cat <<EOF
${Bold}How many people can play this game?${Normal}
This game is designed to be a single-player game, but it can be deployed on 1 VM whilst everyone
is brainstorming together and coming up with ways to tackle the challenge.

${Bold}What is the aim of the game?${Normal}
The aim of the game is to hack your way through several AWS resources ranging from databases
to webservers to IAM systems etc. whilst answering questions (like a Capture The Flag (CTF) game).

${Bold}How do I start a scenario?${Normal}
When you are ready to tackle the challenge, press "1" to play the scenario.

${Bold}How do I quit the game?${Normal}
If you wish to quit the game, without having started a challenge or at the end of one, simply press "4" to quit.

${Bold}What if, whilst playing the game, I try to quit the game?${Normal}
In this case there are 2 options:
	- Exhaust your guesses (wrongly answer the questions) until you have no guesses left. This will result in the game terminating itself.
	- Force quit the game: note that this will keep the resources alive and existing. Afterwards you have to manually go into
 	  folder (${Bold}cd ./Internship/s1${Normal}) of the scenario and type 'terraform destroy -auto-approve' and wait till there is a green box saying "x resources destroyed".

${Bold}NOTES:${Normal}
	- Answers must be given with respect to upper and lowercase. (e.g. "Foo Bar" is not the same as "foo bar")
	- The player has a total of 30 guesses spread over 6 questions. This results in 5 tries per question.
	- It is recommended that the game should be played on a completely new Linux VM. (to avoid the installed and configured items from not working as intend)

${Bold}Don't forget to have fun playing and learn some new tricks along the way ;)${Normal}
EOF
	read -n 1 -s -r -p  $'\x0aPress any key to return to the main menu!\x0a'
        ;;
    "3")echo -e  "\x0a${MainC}---------------------------------------------------------"
        echo "| This interactive blue teaming experience was made by: |"
        echo -e "| ${Blue}Yannick VC. (Cyber Cloud Intern)${MainC}                      |"
        echo -e  "---------------------------------------------------------${ClearColor}"
	read -n 1 -s -r -p  $'\x0aPress any key to return to the main menu!\x0a'
        ;;
    "4")exit 0;;
     * )echo "Invalid option"
        sleep 0.3
        ;;
    esac
done
