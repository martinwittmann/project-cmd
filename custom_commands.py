import click
import importlib.util
import os
import sys

COMMANDS_DIR = 'commands'


class CustomCommands:

    def __init__(self):
        self.script_path = os.path.dirname(__file__)

    def get_projects_commands_paths(self):
        return [os.path.join(self.script_path, COMMANDS_DIR)]

    def get_commands_and_groups(self):
        result = []
        for commands_path in self.get_projects_commands_paths():
            result += self.get_commands_and_groups_for_path(commands_path)
        print(result)
        return result

    def get_commands_and_groups_for_path(self, commands_path):
        commands = []
        for filename in os.listdir(commands_path):
            if filename.startswith('__') or filename.startswith('.'):
                continue

            full_path = os.path.join(commands_path, filename)
            if filename.endswith('.py'):
                commands.append(self.get_global_command(full_path))
            elif os.path.isdir(full_path):
                # This is a group.
                commands += self.get_group(full_path)
        return commands

    def get_global_command(self, filename):
        return self.import_file(filename)
        #module = importlib.import_module(filename)
        #name = os.path.basename(filename)
        #return module[name]

    def get_group(self, path):
        return []

    def import_file(self, filename):
        module_name = os.path.basename(filename)[:-3]
        print('!!!!!!!!!!!!!!')
        print('importing ' + filename + ' - ' + module_name)
        spec = importlib.util.spec_from_file_location(module_name, filename)
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)
        return getattr(module, module_name[:-3])
