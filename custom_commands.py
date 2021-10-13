import importlib.util
import os
import sys
import click


COMMANDS_DIR = 'commands'


class CustomCommands:

    def __init__(self, config):
        self.config = config

    def get_commands_paths(self):
        projects = self.config.get_all_projects()
        paths = []
        for project in projects:
            # TODO Use constant for '.project'.
            path = os.path.join(project['location'], '.project', COMMANDS_DIR)
            if os.path.isdir(path):
                paths.append(path)
        return paths

    def get_custom_commands(self):
        paths = self.get_commands_paths()
        result = []
        for path in paths:
            custom_commands = self.load_custom_commands_from_project(path)
            if isinstance(custom_commands, click.Group):
                result.append(custom_commands)

        return result

    def load_custom_commands_from_project(self, filename):
        module_name = os.path.basename(filename)
        module_path_full = os.path.join(filename, '__init__.py')

        try:
            module_spec = importlib.util.spec_from_file_location(module_name, module_path_full)
            custom_commands_module = importlib.util.module_from_spec(module_spec)
            sys.modules[module_spec.name] = custom_commands_module
            module_spec.loader.exec_module(custom_commands_module)
            return custom_commands_module.commands
        except Exception as e:
            print(e)
            return None
