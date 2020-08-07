highest_num = 100
lowest_num = 0
avg_num = (highest_num + lowest_num) / 2
while True:
  print("Is your secret number ", int(avg_num), 
    "? Enter 'h' to indicate the guess is too high. \
    Enter 'l' to indicate the guess is too low. \
    Enter 'c' to indicate I guessed correctly.", end='')
  y = input()
  if y == "h":
    highest_num = avg_num
    avg_num = (avg_num + lowest_num) / 2
  elif y == "l":
    lowest_num = avg_num
    avg_num = (avg_num + highest_num) / 2
  elif y == "c":
    print("woohoo!")
    break
  else:
    print("Sorry, I did not understand your input.")
