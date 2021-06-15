import click
import os
import sys
import pathlib
import yaml
from util import project_cmd_show_click_exception, debug
from dotenv import dotenv_values

class ConfigKeyNotFoundException(Exception):
    pass

CONFIG_FILENAME = 'project.yml'
ENV_FILENAME = '.env'
DOT_PROJECT_DIR = '.project'
GLOBAL_PROJECT_DIR = '.project'
GLOBAL_CONFIG_FILENAME = 'config.yml'

DEFAULT_PROJECT_CONFIG = {
    'dump_file_extension': '.sql',
    'archive_file_extension': '.tar.gz',
}

DEFAULT_GLOBAL_CONFIG = {}

class ProjectConfig:
    def __init__(self, verbose=0):
        self.verbose = verbose
        self.home_dir = str(pathlib.Path.home())

    def init_project_data(self, project=None):
        self.config_file = self.get_config_location(project)
        self.project_dir = os.path.dirname(self.config_file)
        self.dot_project_dir = os.path.join(self.project_dir, DOT_PROJECT_DIR)
        self._config = self.load_config(self.config_file, DEFAULT_PROJECT_CONFIG)
        self._global_config = self.get_global_config()
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
            if self.verbose > 0:
                debug('Searching project config at {}'.format(filename))
            if os.path.isfile(filename):
                if self.verbose > 0:
                    debug('Found project config at {}'.format(filename))
                return filename
            else:
                path = str(pathlib.Path(path).resolve().parent)
                if self.is_root(path) or self.is_home_dir(path):
                    raise click.ClickException('No configuration file ({}) found. Stopped at {}.'.format(CONFIG_FILENAME, path))

    def load_config(self, filename, default_config={}):
        with open(filename) as file:
            config = yaml.load(file, yaml.FullLoader)
            return {**default_config, **config}

    def get_project_path(self, project):
        path = os.path.join(self.get_global_projects_dir(), project)
        return os.path.realpath(path)


    def is_home_dir(self, path):
        return path is self.home_dir

    def is_root(self, path):
        return os.path.dirname(path) == path
    def has_key(self, key):
        try:
            self.get(key)
            return True
        except Exception:
            return False

    def get(self, key='', config=None):
        try:
            if config is None:
                if key.startswith('global.'):
                    config = self._global_config
                    key = key[7:]
                else:
                    config = self._config

            result = config
            parts = key.split('.')
            for part in parts:
                result = result[part]
            return result

        except ConfigKeyNotFoundException as e:
            click.secho('ERROR ', fg='bright_red', bold=True, nl=False)
            click.echo('Getting config key: ' + str(e))
            return None

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

    def get_global_config(self):
        filename = os.path.join(self.get_global_config_location(), GLOBAL_CONFIG_FILENAME)
        return self.load_config(filename, DEFAULT_GLOBAL_CONFIG)
