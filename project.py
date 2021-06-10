import click
import util

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = util.project_cmd_show_click_exception

VERSION = '0.4'

import commands


@click.group()
def main():
    pass



main.add_command(commands.change_directory)
main.add_command(commands.change_directory_alias)

main.add_command(commands.info)
main.add_command(commands.info_alias)

main.add_command(commands.list_projects)
main.add_command(commands.list_project_alias)

main.add_command(commands.run_script)
main.add_command(commands.run_script_alias)


main.add_command(commands.status)
main.add_command(commands.status_alias)
