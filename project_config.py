import click
import os
import pathlib
import yaml
from dotenv import dotenv_values

CONFIG_FILENAME = 'project.yml'
ENV_FILENAME = '.env'
DOT_PROJECT_DIR = '.project'

class ProjectConfig:
    def __init__(self, verbose=0):
        self.path = os.getcwd()
        self.verbose = verbose
        self.home_dir = str(pathlib.Path.home())
        self.project_dir = self.get_config_location()
        self.dot_project_dir = os.path.join(self.project_dir, DOT_PROJECT_DIR)
        self.config_file = os.path.join(self.project_dir, CONFIG_FILENAME)
        with open(self.config_file) as file:
            self._config = yaml.load(file, yaml.FullLoader)
        self.env = dotenv_values(os.path.join(self.project_dir, ENV_FILENAME))

    def get_config_location(self):
        config_filename = False
        current_path = self.path
        if self.verbose > 0:
            click.echo('Searching project config...')

        while not config_filename:
            filename = os.path.join(current_path, CONFIG_FILENAME)
            if self.verbose > 1:
                click.echo('Searching project config at {}'.format(filename))
            if os.path.isfile(filename):
                if self.verbose > 0:
                    click.echo('Found project config at {}'.format(config_filename))
                return current_path
            else:
                current_path = str(pathlib.Path(current_path).resolve().parent)
                if self.is_root(current_path) or self.is_home_dir(current_path):
                    raise Exception('No configuration file found. Stopped at {}.'
                                    .format(current_path))



    def is_home_dir(self, path):
        return path is self.home_dir

    def is_root(self, path):
        return os.path.dirname(path) == path

    def get(self, key=''):
        if key == '':
            return self._config

        parts = key.split('.')
        if len(parts) == 1:
            return self._config[key]
        else:
            parent_key = '.'.join(parts[:-1])
            parent = self.get(parent_key)
            return parent[parts[1]]
