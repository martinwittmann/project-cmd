import click
import context
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

class DynamicCommands(click.MultiCommand):

    command_path_mapping = {}
    commands_list = None

    def get_commands_paths(self):
        projects = config.get_all_projects()
        global_commands_path = os.path.join(script_path, COMMANDS_DIR)
        commands_paths = [
            global_commands_path,
        ]
        for project in projects:
            commands_path = os.path.join(project['location'], COMMANDS_DIR)
            if (os.path.isdir(commands_path)):
                commands_paths.append(commands_path)

        return commands_paths

    def get_commands_for_path(self, path):
        commands = []
        for filename in os.listdir(path):
            if filename.endswith('.py') and filename != '__init__.py':
                commands.append(filename[:-3])
                self.command_path_mapping[filename[:-3]] = path
            elif os.path.isdir(os.path.join(path, filename)) and not filename.startswith('__') and not filename.startswith('.'):
                commands += self.get_commands_for_path(os.path.join(path, filename))
        return commands

    def get_filename_for_command(self, command):
        return os.path.join(self.command_path_mapping[command], command + '.py')

    def list_commands(self, ctx):
        if self.commands_list is None:
            commands = []
            for path in self.get_commands_paths():
                commands += self.get_commands_for_path(path)
            commands.sort()
            print(commands)
            self.commands_list = commands

        return self.commands_list

    def get_command(self, ctx, name):
        namespace = {}
        # We need to call list_commands to command_path_mapping so we can find
        # out the path of the requested command.
        self.list_commands(ctx)
        context.init(ctx)
        filename = self.get_filename_for_command(name)
        with open(filename) as f:
            code = compile(f.read(), filename, 'exec')
            eval(code, namespace, namespace)
        return namespace[name]

custom_commands_and_groups = custom_commands.CustomCommands()
#@click.CommandCollection(sources=ll)
#@click.command(cls=DynamicCommands)
#@click.pass_context
#def main(ctx):
    #"""Project documentation text."""
    #pass


all_commands = [commands.commands]
main = click.CommandCollection(sources=all_commands)

if __name__ == '__main__':
    main()

