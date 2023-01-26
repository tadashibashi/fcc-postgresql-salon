#!/bin/bash
# Salon Appointment Scheduler
# by Aaron Ishibashi
#
# Takes user input to schedule appointments in a local PostgreSQL database
# Written for the freeCodeCamp Relational Database project
#
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Welcome to Le Beauty Salon! ~~~~~\n"

# trim a string of white-space at both front and end
TRIM() {
	if [[ $1 ]]
	then
		echo $(echo $1 | sed -E 's/^ *| *$//g')
		return 0
	else
		return 1
	fi
}

# run the main program
MAIN_MENU() {
	# display any incoming message arg before showing the main menu
	if [[ $1 ]]
	then
		echo -e "\n$1"
	fi

    # display welcome message with available services
	echo -e "\nWelcome to Le Beauty Salon, how can I help you?"

	SERVICE_LIST=$($PSQL "SELECT service_id, name FROM services")
	echo "$SERVICE_LIST" | while read SERVICE_ID BAR SERVICE_NAME
	do
		echo "$SERVICE_ID) $SERVICE_NAME"
	done

    # get user's service request
	echo -e "\nPlease enter the number of your requested service:"
	read SERVICE_ID_SELECTED

	# if invalid service id entered
	if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
	then
		# return to main menu
		MAIN_MENU "Please input a valid number."
		return
	fi

    # get name from service, checking if it exists
	SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
	if [[ -z $SERVICE_NAME ]]
	then
		MAIN_MENU "I'm sorry, I couldn't find that service."
		return
	fi

	# ask for phone number (identifies customer)
	echo -e "\nCould I get your phone number?"
	read CUSTOMER_PHONE

	# if customer/phone does not exist
	CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
	if [[ -z $CUSTOMER_NAME ]]
	then
		# ask for name
		echo -e "\nCould I get your name?"
		read CUSTOMER_NAME

		# add new customer to database
		INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
	fi

	# get customer id
	CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

    # read appointment time from user
	echo -e "\nPlease enter a time for your appointment:"
	read SERVICE_TIME

	# insert appointment
	INSERT_APPT_RESULT=$($PSQL "INSERT INTO appointments(service_id, customer_id, time) VALUES($SERVICE_ID_SELECTED, $CUSTOMER_ID, '$SERVICE_TIME')")

	# if insertion failed
	if [[ $INSERT_APPT_RESULT != "INSERT 0 1" ]]
	then
		# redirect to main menu
		MAIN_MENU "I'm sorry, there was a problem while processing your appointment."
		return
	fi

	# display result
	echo -e "\nI have put you down for a $(TRIM $SERVICE_NAME) at $(TRIM $SERVICE_TIME), $(TRIM $CUSTOMER_NAME)."
}

MAIN_MENU
