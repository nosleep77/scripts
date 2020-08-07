import random

print("Game: rock, paper, scissors")
choices = ["rock", "paper", "scissors"]

while True:

  human_choice = input("(enter Player 1's choice or q to quit): ")
  if human_choice == "q":
    exit()

  comp_choice = random.choice(choices)

  print("You selected " + human_choice)
  print("Computer selected " + comp_choice)

  if human_choice == "rock":
    if comp_choice == "rock":
      print("TIE!")
    elif comp_choice == "paper":
      print("Paper covers Rock!")
    elif comp_choice == "scissors":
      print("Rock breaks scissors!")
    else:
      print("Didn't understand your input")

  elif human_choice == "paper":
    if comp_choice == "rock":
      print("Paper covers Rock!")
    elif comp_choice == "paper":
      print("TIE!")
    elif comp_choice == "scissors":
      print("Scissors cuts paper!")
    else:
      print("Didn't understand your input")

  elif human_choice == "scissors":
    if comp_choice == "rock":
      print("Rock breaks scissors!")
    elif comp_choice == "paper":
      print("Scissors cuts paper!")
    elif comp_choice == "scissors":
      print("TIE!")
    else:
      print("Didn't understand your input")
  
  else:
    print("Sorry didn't understand your input")
