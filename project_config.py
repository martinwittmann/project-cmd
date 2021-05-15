import click
import os
import sys
import pathlib
import yaml
from project_util import project_cmd_show_click_exception, debug
from dotenv import dotenv_values

CONFIG_FILENAME = 'project.yml'
ENV_FILENAME = '.env'
DOT_PROJECT_DIR = '.project'
GLOBAL_PROJECT_DIR = '.project-cmd'

class ProjectConfig:
    def __init__(self, project=None, verbose=0):
        self.verbose = verbose
        self.home_dir = str(pathlib.Path.home())

        self.config_file = self.get_config_location(project)
        self.project_dir = os.path.dirname(self.config_file)
        self.dot_project_dir = os.path.join(self.project_dir, DOT_PROJECT_DIR)
        self._config = self.load_config(self.config_file)
        self.env = dotenv_values(os.path.join(self.project_dir, ENV_FILENAME))

    def get_config_location(self, project=None):
        result = False
        if project is None:
            path = os.getcwd()
        else:
            path = self.get_project_path(project)

        if self.verbose > 0:
            debug('Searching project config...')
        while not result:
            filename = os.path.join(path, CONFIG_FILENAME)
            if self.verbose > 1:
                debug('Searching project config at {}'.format(filename))
            if os.path.isfile(filename):
                if self.verbose > 0:
                    debug('Found project config at {}'.format(filename))
                return filename
            else:
                path = str(pathlib.Path(path).resolve().parent)
                if self.is_root(path) or self.is_home_dir(path):
                    raise click.ClickException('No configuration file ({}) found. Stopped at {}.'.format(CONFIG_FILENAME, path))

    def load_config(self, filename):
        with open(filename) as file:
            return yaml.load(file, yaml.FullLoader)

    def get_project_path(self, project):
        path = os.path.join(self.get_global_projects_dir(), project)
        return os.path.realpath(path)


    def is_home_dir(self, path):
        return path is self.home_dir

    def is_root(self, path):
        return os.path.dirname(path) == path

    def get(self, key='', config=None):
        if config is None:
            config = self._config

        if key == '':
            return config

        parts = key.split('.')
        if len(parts) == 1:
            return config[key]
        else:
            parent_key = '.'.join(parts[:-1])
            parent = self.get(parent_key, config=config)
            return parent[parts[1]]

    def get_global_config_location(self):
        return os.path.join(self.home_dir, GLOBAL_PROJECT_DIR)

    def get_global_projects_dir(self):
        return os.path.join(self.get_global_config_location(), 'projects')

    def is_project_dir(self, project_path):
        try:
            self.get_config_location(project_path)
            return True
        except Exception:
            return False

    def get_all_projects(self):
        result = []
        global_projects_dir = self.get_global_projects_dir()
        for raw_project_path in os.listdir(global_projects_dir):
            project_path = os.path.join(global_projects_dir, raw_project_path)
            project_path = os.path.realpath(project_path)
            config_file = self.get_config_location(project_path)
            config = self.load_config(config_file)
            if not config:
                continue
            result.append({
                'id': self.get('id', config=config),
                'name': self.get('name', config=config),
                'location': project_path,
            })
        return result
