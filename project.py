import click
import custom_commands
import util
import os
import project_config
import commands

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = util.project_cmd_show_click_exception

VERSION = '0.1'
COMMANDS_DIR = 'commands'

script_path = os.path.dirname(__file__)
config = project_config.ProjectConfig()

# This needs click's context to work!
custom_commands_manager = custom_commands.CustomCommands(config)
custom_commands = custom_commands_manager.get_custom_commands()
all_commands = [commands.commands] + custom_commands

main_help = ""
main = click.CommandCollection(sources=all_commands, help=main_help)


