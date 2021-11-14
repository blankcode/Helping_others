#!/bin/bash
#
# Created from:
# https://www.reddit.com/r/bash/comments/qihah6/how_to_take_a_single_digit_as_input_and_autoenter/
# Title: How to take a single digit as input and auto-enter?
# Post: I want to write a program that takes only a single digit as input and starts
#       executing the further stuff. So input is only 1 keypress.
# Response:
# I added some feedback and a break to break the loop, other wise it just keeps asking.

while true; do
  workspace=0
  echo -ne "Choose a, b, c, d, or any other key for Default\nInput here: "
  read -r -n 1 tag
  echo -ne "\nThank you for choosing $tag"
  sleep .3
  case $tag in
  a)
    workspace=1
    ;;

  b)
    workspace=2
    ;;

  c | d)
    workspace=3
    ;;

  *)
    workspace=4
    ;;
  esac
  echo -ne "Echoing the command output:\nxdotool key Super+m Super+Shift+$workspace"
  break
done
