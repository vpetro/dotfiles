function wmd() {
    watchmedo shell-command --recursive --patterns="*.py" --command="clear; nosetests --rednose Tests/"
}
